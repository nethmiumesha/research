use crate::actors::messages::{ExecutionResult, ProcessorMessage, WorkerMessage};
use crate::executor::ExecutorLogic;
use crate::load_balancer::{LoadBalancer, ProcessDecision};
use crate::resources::SharedResources;
use antegen_thread_program::state::Thread;
use ractor::{Actor, ActorProcessingErr, ActorRef};
use solana_sdk::{clock::Clock, message::Message, pubkey::Pubkey, transaction::Transaction};
use std::error::Error;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{broadcast, OwnedSemaphorePermit};
const MAX_ATTEMPTS: u32 = 5;
const CONFIRMATION_TIMEOUT_SECS: u64 = 30;
const BASE_RETRY_DELAY_MS: u64 = 500;
const TPU_RETRY_INTERVAL_MS: u64 = 2000;
const TRIGGER_RETRY_DEADLINE_SECS: u64 = 10;
fn is_trigger_not_ready_error(error: &str) -> bool {
    error.contains("Custom(6004)") || error.contains("6004")
}
fn is_thread_paused_error(error: &str) -> bool {
    error.contains("Custom(6006)") || error.contains("6006")
}
pub struct WorkerActor;
pub struct WorkerArgs {
    pub thread_pubkey: Pubkey,
    pub thread: Thread,
    pub is_overdue: bool,
    pub overdue_seconds: i64,
    pub permit: OwnedSemaphorePermit,
    pub processor_ref: ActorRef<ProcessorMessage>,
    pub clock_rx: broadcast::Receiver<Clock>,
    pub resources: SharedResources,
    pub executor: ExecutorLogic,
    pub load_balancer: Arc<LoadBalancer>,
}
pub struct WorkerState {
    thread_pubkey: Pubkey,
    #[allow(dead_code)]
    thread: Thread,
    _permit: OwnedSemaphorePermit,
    #[allow(dead_code)]
    processor_ref: ActorRef<ProcessorMessage>,
    cancelled: Arc<AtomicBool>,
}
impl Actor for WorkerActor {
    type Msg = WorkerMessage;
    type State = WorkerState;
    type Arguments = WorkerArgs;
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        args: Self::Arguments,
    ) -> Result<Self::State, Box<dyn Error + Send + Sync>> {
        log::debug!("WorkerActor started for thread: {}", args.thread_pubkey);
        let cancelled = Arc::new(AtomicBool::new(false));
        let state = WorkerState {
            thread_pubkey: args.thread_pubkey,
            thread: args.thread.clone(),
            _permit: args.permit,
            processor_ref: args.processor_ref.clone(),
            cancelled: cancelled.clone(),
        };
        let thread_pubkey = args.thread_pubkey;
        let thread = args.thread;
        let is_overdue = args.is_overdue;
        let overdue_seconds = args.overdue_seconds;
        let processor_ref = args.processor_ref;
        let resources = args.resources;
        let executor = args.executor;
        let load_balancer = args.load_balancer;
        let cancelled_flag = cancelled;
        let myself_ref = myself.clone();
        tokio::spawn(async move {
            let result = execute_thread(
                thread_pubkey,
                thread.clone(),
                is_overdue,
                overdue_seconds,
                &resources,
                &executor,
                &load_balancer,
                &cancelled_flag,
            )
            .await;
            if let Err(e) = processor_ref.send_message(ProcessorMessage::WorkerCompleted(result)) {
                log::error!(
                    "Failed to send completion result for thread {}: {:?}",
                    thread_pubkey,
                    e
                );
            }
            myself_ref.stop(Some("execution complete".to_string()));
        });
        Ok(state)
    }
    async fn handle(
        &self,
        _myself: ActorRef<Self::Msg>,
        message: Self::Msg,
        state: &mut Self::State,
    ) -> Result<(), ActorProcessingErr> {
        match message {
            WorkerMessage::Cancel => {
                state.cancelled.store(true, Ordering::Relaxed);
                Ok(())
            }
        }
    }
    async fn post_stop(
        &self,
        _myself: ActorRef<Self::Msg>,
        state: &mut Self::State,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        log::debug!("WorkerActor for {} stopped", state.thread_pubkey);
        Ok(())
    }
}
async fn execute_thread(
    thread_pubkey: Pubkey,
    thread: Thread,
    is_overdue: bool,
    overdue_seconds: i64,
    resources: &SharedResources,
    executor: &ExecutorLogic,
    load_balancer: &LoadBalancer,
    cancelled: &AtomicBool,
) -> ExecutionResult {
    if cancelled.load(Ordering::Relaxed) {
        log::debug!(
            "Worker cancelled before execution for thread: {}",
            thread_pubkey
        );
        return ExecutionResult::failed(
            thread_pubkey,
            "Cancelled before execution".to_string(),
            0,
        );
    }
    let current_last_executor = match resources.cache.get(&thread_pubkey).await {
        Some(cached) => {
            use anchor_lang::AccountDeserialize;
            match Thread::try_deserialize(&mut cached.data.as_slice()) {
                Ok(fresh_thread) => {
                    if fresh_thread.exec_count != thread.exec_count {
                        log::debug!(
                            "Thread {} exec_count changed ({} -> {}), skipping",
                            thread_pubkey,
                            thread.exec_count,
                            fresh_thread.exec_count
                        );
                        return ExecutionResult::failed(
                            thread_pubkey,
                            "Thread already executed (exec_count changed)".to_string(),
                            0,
                        );
                    }
                    fresh_thread.last_executor
                }
                Err(_) => thread.last_executor,
            }
        }
        None => thread.last_executor,
    };
    let decision = match load_balancer
        .should_process(&thread_pubkey, &current_last_executor, is_overdue, overdue_seconds)
        .await
    {
        Ok(d) => d,
        Err(e) => {
            log::error!(
                "Load balancer error for thread {}: {:?}",
                thread_pubkey,
                e
            );
            return ExecutionResult::failed(
                thread_pubkey,
                format!("Load balancer error: {}", e),
                0,
            );
        }
    };
    match decision {
        ProcessDecision::Skip => {
            log::debug!(
                "Load balancer decided to skip thread {} (owned by another executor)",
                thread_pubkey
            );
            return ExecutionResult::failed(
                thread_pubkey,
                "Skipped by load balancer".to_string(),
                0,
            );
        }
        ProcessDecision::AtCapacity => {
            log::debug!(
                "Load balancer at capacity for thread {}, skipping",
                thread_pubkey
            );
            return ExecutionResult::failed(
                thread_pubkey,
                "At capacity".to_string(),
                0,
            );
        }
        ProcessDecision::Process => {
            log::debug!("Load balancer approved processing thread {}", thread_pubkey);
        }
    }
    if current_last_executor.eq(&Pubkey::default()) {
        let delay = load_balancer.thread_process_delay();
        if !delay.is_zero() {
            log::debug!(
                "Thread {} - waiting {:?} before claiming new thread",
                thread_pubkey,
                delay
            );
            tokio::time::sleep(delay).await;
            if let Some(cached) = resources.cache.get(&thread_pubkey).await {
                use anchor_lang::AccountDeserialize;
                if let Ok(t) = Thread::try_deserialize(&mut cached.data.as_slice()) {
                    if !t.last_executor.eq(&Pubkey::default()) {
                        log::debug!(
                            "Thread {} claimed by {} during delay, skipping",
                            thread_pubkey,
                            t.last_executor
                        );
                        return ExecutionResult::failed(
                            thread_pubkey,
                            "Claimed during delay".to_string(),
                            0,
                        );
                    }
                }
            }
        }
    }
    let trigger_retry_deadline = Instant::now() + Duration::from_secs(TRIGGER_RETRY_DEADLINE_SECS);
    let (instructions, _priority_fee) = loop {
        if cancelled.load(Ordering::Relaxed) {
            return ExecutionResult::failed(
                thread_pubkey,
                "Cancelled during build".to_string(),
                0,
            );
        }
        if Instant::now() > trigger_retry_deadline {
            return ExecutionResult::failed(
                thread_pubkey,
                "Trigger window expired while waiting for trigger time".to_string(),
                0,
            );
        }
        match executor
            .build_execute_transaction(&thread_pubkey, &thread)
            .await
        {
            Ok(result) => break result,
            Err(e) => {
                let error_str = e.to_string();
                if is_trigger_not_ready_error(&error_str) {
                    log::debug!(
                        "Thread {} trigger not ready (6004), retrying in 500ms",
                        thread_pubkey
                    );
                    tokio::time::sleep(Duration::from_millis(500)).await;
                    continue;
                } else if is_thread_paused_error(&error_str) {
                    log::debug!(
                        "Thread {} is paused (6006), skipping execution",
                        thread_pubkey
                    );
                    return ExecutionResult::failed(
                        thread_pubkey,
                        "Thread is paused".to_string(),
                        0,
                    );
                } else {
                    log::error!(
                        "Failed to build transaction for thread {}: {:?}",
                        thread_pubkey,
                        e
                    );
                    return ExecutionResult::failed(
                        thread_pubkey,
                        format!("Transaction build failed: {}", e),
                        0,
                    );
                }
            }
        }
    };
    log::info!(
        "{}: built {} instruction(s)",
        thread_pubkey,
        instructions.len(),
    );
    let mut attempt = 0;
    let mut last_error = String::new();
    while attempt < MAX_ATTEMPTS {
        attempt += 1;
        if cancelled.load(Ordering::Relaxed) {
            log::debug!(
                "Worker cancelled during execution for thread: {}",
                thread_pubkey
            );
            return ExecutionResult::failed(
                thread_pubkey,
                "Cancelled during execution".to_string(),
                attempt,
            );
        }
        log::debug!(
            "Submitting transaction for thread {} (attempt {}/{})",
            thread_pubkey,
            attempt,
            MAX_ATTEMPTS
        );
        let (blockhash, _) = match resources.rpc_client.get_latest_blockhash().await {
            Ok(bh) => bh,
            Err(e) => {
                last_error = format!("Failed to get blockhash: {}", e);
                log::warn!(
                    "Failed to get blockhash for thread {} (attempt {}): {:?}",
                    thread_pubkey,
                    attempt,
                    e
                );
                tokio::time::sleep(Duration::from_millis(
                    BASE_RETRY_DELAY_MS * (1 << attempt.min(4)),
                ))
                .await;
                continue;
            }
        };
        let message = Message::new(&instructions, Some(&executor.pubkey()));
        let tx = Transaction::new(&[executor.keypair().as_ref()], message, blockhash);
        let signature = tx.signatures[0];
        log::info!("{}: sent", thread_pubkey);
        log::debug!("  txn: {}", signature);
        let mut tpu_confirmed = false;
        if let Some(tpu_client) = &resources.tpu_client {
            let start = Instant::now();
            let timeout = Duration::from_secs(CONFIRMATION_TIMEOUT_SECS);
            let mut last_tpu_send = Instant::now();
            if let Err(e) = tpu_client.send_transaction(&tx).await {
                log::debug!("Initial TPU send failed: {}", e);
            }
            loop {
                if start.elapsed() > timeout {
                    log::debug!("TPU confirmation timeout, falling back to RPC");
                    break;
                }
                if last_tpu_send.elapsed() > Duration::from_millis(TPU_RETRY_INTERVAL_MS) {
                    if let Err(e) = tpu_client.send_transaction(&tx).await {
                        log::debug!("TPU re-send failed: {}", e);
                    }
                    last_tpu_send = Instant::now();
                }
                match resources.rpc_client.get_signature_status(&signature).await {
                    Ok(Some(Ok(()))) => {
                        tpu_confirmed = true;
                        break;
                    }
                    Ok(Some(Err(e))) => {
                        let error_str = format!("{:?}", e);
                        if is_trigger_not_ready_error(&error_str) {
                            log::debug!(
                                "{}: 6004 on-chain (trigger not ready), will retry",
                                thread_pubkey
                            );
                            break;
                        }
                        if is_thread_paused_error(&error_str) {
                            log::debug!(
                                "{}: 6006 on-chain (thread paused), skipping",
                                thread_pubkey
                            );
                            return ExecutionResult::failed(
                                thread_pubkey,
                                "Thread is paused".to_string(),
                                attempt,
                            );
                        }
                        log::warn!("{}: transaction failed on-chain: {:?}", thread_pubkey, e);
                        let _ = load_balancer
                            .record_execution_result(&thread_pubkey, false, chrono::Utc::now().timestamp())
                            .await;
                        return ExecutionResult::failed(
                            thread_pubkey,
                            format!("Transaction failed on-chain: {:?}", e),
                            attempt,
                        );
                    }
                    Ok(None) => {
                    }
                    Err(e) => {
                        log::debug!("Error checking signature status: {:?}", e);
                    }
                }
                tokio::time::sleep(Duration::from_millis(500)).await;
            }
        }
        if tpu_confirmed {
            log::info!("{}: confirmed", thread_pubkey);
            log::debug!("  txn: {}", signature);
            let _ = load_balancer
                .record_execution_result(&thread_pubkey, true, chrono::Utc::now().timestamp())
                .await;
            return ExecutionResult::success(thread_pubkey);
        }
        match resources.rpc_client.send_transaction(&tx).await {
            Ok(sig) => {
                log::debug!("Transaction sent via RPC: {}", sig);
            }
            Err(e) => {
                last_error = format!("Transaction send failed: {}", e);
                log::warn!(
                    "Failed to send transaction for thread {} (attempt {}): {:?}",
                    thread_pubkey,
                    attempt,
                    e
                );
                let _ = load_balancer
                    .record_execution_result(&thread_pubkey, false, chrono::Utc::now().timestamp())
                    .await;
                tokio::time::sleep(Duration::from_millis(
                    BASE_RETRY_DELAY_MS * (1 << attempt.min(4)),
                ))
                .await;
                continue;
            }
        }
        match wait_for_confirmation(&resources.rpc_client, &signature, CONFIRMATION_TIMEOUT_SECS).await {
            Ok(()) => {
                log::info!("{}: confirmed", thread_pubkey);
                log::debug!("  txn: {}", signature);
                let _ = load_balancer
                    .record_execution_result(&thread_pubkey, true, chrono::Utc::now().timestamp())
                    .await;
                return ExecutionResult::success(thread_pubkey);
            }
            Err(e) => {
                last_error = format!("Confirmation failed: {}", e);
                if is_trigger_not_ready_error(&e) {
                    log::debug!(
                        "{}: 6004 on RPC confirmation (trigger not ready), will retry",
                        thread_pubkey
                    );
                } else if is_thread_paused_error(&e) {
                    log::debug!(
                        "{}: 6006 on RPC confirmation (thread paused), stopping",
                        thread_pubkey
                    );
                    return ExecutionResult::failed(
                        thread_pubkey,
                        "Thread is paused".to_string(),
                        attempt,
                    );
                } else {
                    log::warn!(
                        "Transaction confirmation failed for thread {} (attempt {}): {:?}",
                        thread_pubkey,
                        attempt,
                        e
                    );
                    let _ = load_balancer
                        .record_execution_result(&thread_pubkey, false, chrono::Utc::now().timestamp())
                        .await;
                }
                if attempt < MAX_ATTEMPTS {
                    tokio::time::sleep(Duration::from_millis(
                        BASE_RETRY_DELAY_MS * (1 << attempt.min(4)),
                    ))
                    .await;
                }
            }
        }
    }
    log::error!(
        "All {} attempts failed for thread {}: {}",
        MAX_ATTEMPTS,
        thread_pubkey,
        last_error
    );
    ExecutionResult::failed(thread_pubkey, last_error, attempt)
}
async fn wait_for_confirmation(
    rpc_client: &crate::rpc::RpcPool,
    signature: &solana_sdk::signature::Signature,
    timeout_secs: u64,
) -> Result<(), String> {
    let start = std::time::Instant::now();
    let timeout = Duration::from_secs(timeout_secs);
    loop {
        if start.elapsed() > timeout {
            return Err(format!(
                "Confirmation timeout after {}s",
                timeout_secs
            ));
        }
        match rpc_client.get_signature_status(signature).await {
            Ok(Some(result)) => match result {
                Ok(()) => return Ok(()),
                Err(e) => return Err(format!("Transaction failed: {:?}", e)),
            },
            Ok(None) => {
                tokio::time::sleep(Duration::from_millis(500)).await;
            }
            Err(e) => {
                log::debug!("Error checking signature status: {:?}", e);
                tokio::time::sleep(Duration::from_millis(500)).await;
            }
        }
    }
}