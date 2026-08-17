#![cfg(feature = "test-sbf")]
mod program_test;
use {
    program_test::*,
    solana_program::{
        instruction::{AccountMeta, Instruction},
        program_error::ProgramError,
        sysvar::clock,
    },
    solana_program_test::tokio,
    spl_governance::{
        error::GovernanceError,
        state::enums::{ProposalState, TransactionExecutionStatus},
    },
};
#[tokio::test]
async fn test_execute_mint_transaction() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governed_mint_cookie = governance_test.with_governed_mint(&governance_cookie).await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_mint_tokens_transaction(
            &governed_mint_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
            0,
            None,
        )
        .await
        .unwrap();
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test
        .advance_clock_by_min_timespan(
            governance_cookie.account.config.transactions_hold_up_time as u64,
        )
        .await;
    let clock = governance_test.bench.get_clock().await;
    governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    let yes_option = proposal_account.options.first().unwrap();
    assert_eq!(1, yes_option.transactions_executed_count);
    assert_eq!(ProposalState::Completed, proposal_account.state);
    assert_eq!(Some(clock.unix_timestamp), proposal_account.closed_at);
    assert_eq!(Some(clock.unix_timestamp), proposal_account.executing_at);
    let proposal_transaction_account = governance_test
        .get_proposal_transaction_account(&proposal_transaction_cookie.address)
        .await;
    assert_eq!(
        Some(clock.unix_timestamp),
        proposal_transaction_account.executed_at
    );
    assert_eq!(
        TransactionExecutionStatus::Success,
        proposal_transaction_account.execution_status
    );
    let instruction_token_account = governance_test
        .get_token_account(&proposal_transaction_cookie.account.instructions[0].accounts[1].pubkey)
        .await;
    assert_eq!(10, instruction_token_account.amount);
}
#[tokio::test]
async fn test_execute_transfer_transaction() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governed_token_account_cookie = governance_test
        .with_governed_token_account(&governance_cookie)
        .await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_transfer_tokens_transaction(
            &governed_token_account_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
            None,
        )
        .await
        .unwrap();
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test
        .advance_clock_by_min_timespan(
            governance_cookie.account.config.transactions_hold_up_time as u64,
        )
        .await;
    let clock = governance_test.bench.get_clock().await;
    governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    let yes_option = proposal_account.options.first().unwrap();
    assert_eq!(1, yes_option.transactions_executed_count);
    assert_eq!(ProposalState::Completed, proposal_account.state);
    assert_eq!(Some(clock.unix_timestamp), proposal_account.closed_at);
    assert_eq!(Some(clock.unix_timestamp), proposal_account.executing_at);
    let proposal_transaction_account = governance_test
        .get_proposal_transaction_account(&proposal_transaction_cookie.address)
        .await;
    assert_eq!(
        Some(clock.unix_timestamp),
        proposal_transaction_account.executed_at
    );
    assert_eq!(
        TransactionExecutionStatus::Success,
        proposal_transaction_account.execution_status
    );
    let instruction_token_account = governance_test
        .get_token_account(&proposal_transaction_cookie.account.instructions[0].accounts[1].pubkey)
        .await;
    assert_eq!(15, instruction_token_account.amount);
}
#[tokio::test]
#[ignore]
async fn test_execute_upgrade_program_transaction() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governed_program_cookie = governance_test
        .with_governed_program(&governance_cookie)
        .await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_upgrade_program_transaction(
            &governance_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test
        .advance_clock_by_min_timespan(
            governance_cookie.account.config.transactions_hold_up_time as u64,
        )
        .await;
    let governed_program_ix = Instruction::new_with_bytes(
        governed_program_cookie.address,
        &[0],
        vec![AccountMeta::new(clock::id(), false)],
    );
    let err = governance_test
        .bench
        .process_transaction(&[governed_program_ix.clone()], None)
        .await
        .err()
        .unwrap();
    assert_eq!(ProgramError::Custom(42), err);
    let clock = governance_test.bench.get_clock().await;
    governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    let yes_option = proposal_account.options.first().unwrap();
    assert_eq!(1, yes_option.transactions_executed_count);
    assert_eq!(ProposalState::Completed, proposal_account.state);
    assert_eq!(Some(clock.unix_timestamp), proposal_account.closed_at);
    assert_eq!(Some(clock.unix_timestamp), proposal_account.executing_at);
    let proposal_transaction_account = governance_test
        .get_proposal_transaction_account(&proposal_transaction_cookie.address)
        .await;
    assert_eq!(
        Some(clock.unix_timestamp),
        proposal_transaction_account.executed_at
    );
    assert_eq!(
        TransactionExecutionStatus::Success,
        proposal_transaction_account.execution_status
    );
    governance_test.advance_clock().await;
    let err = governance_test
        .bench
        .process_transaction(&[governed_program_ix.clone()], None)
        .await
        .err()
        .unwrap();
    assert_eq!(ProgramError::Custom(43), err);
}
#[tokio::test]
#[ignore]
async fn test_execute_proposal_transaction_with_invalid_state_errors() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governed_mint_cookie = governance_test.with_governed_mint(&governance_cookie).await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie1 = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let signatory_record_cookie2 = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_mint_tokens_transaction(
            &governed_mint_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
            0,
            None,
        )
        .await
        .unwrap();
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidStateCannotExecuteTransaction.into()
    );
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie1)
        .await
        .unwrap();
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidStateCannotExecuteTransaction.into()
    );
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie2)
        .await
        .unwrap();
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidStateCannotExecuteTransaction.into()
    );
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test.advance_clock().await;
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::CannotExecuteTransactionWithinHoldUpTime.into()
    );
    governance_test
        .advance_clock_by_min_timespan(
            governance_cookie.account.config.transactions_hold_up_time as u64,
        )
        .await;
    governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(ProposalState::Completed, proposal_account.state);
    governance_test.advance_clock().await;
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidStateCannotExecuteTransaction.into()
    );
}
#[tokio::test]
async fn test_execute_proposal_transaction_for_other_proposal_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governed_mint_cookie = governance_test.with_governed_mint(&governance_cookie).await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_mint_tokens_transaction(
            &governed_mint_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
            0,
            None,
        )
        .await
        .unwrap();
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test
        .advance_clock_by_min_timespan(
            governance_cookie.account.config.transactions_hold_up_time as u64,
        )
        .await;
    let token_owner_record_cookie2 = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie2 = governance_test
        .with_proposal(&token_owner_record_cookie2, &mut governance_cookie)
        .await
        .unwrap();
    governance_test.advance_clock().await;
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie2, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidProposalForProposalTransaction.into()
    );
}
#[tokio::test]
async fn test_execute_mint_transaction_twice_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governed_mint_cookie = governance_test.with_governed_mint(&governance_cookie).await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_mint_tokens_transaction(
            &governed_mint_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
            0,
            None,
        )
        .await
        .unwrap();
    governance_test
        .with_nop_transaction(&mut proposal_cookie, &token_owner_record_cookie, 0, None)
        .await
        .unwrap();
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test
        .advance_clock_by_min_timespan(
            governance_cookie.account.config.transactions_hold_up_time as u64,
        )
        .await;
    governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .unwrap();
    governance_test.advance_clock().await;
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::TransactionAlreadyExecuted.into());
}
#[tokio::test]
async fn test_execute_transaction_with_create_proposal_and_execute_in_single_slot_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.transactions_hold_up_time = 0;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let governed_mint_cookie = governance_test.with_governed_mint(&governance_cookie).await;
    let mut proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let signatory_record_cookie = governance_test
        .with_signatory(
            &proposal_cookie,
            &governance_cookie,
            &token_owner_record_cookie,
        )
        .await
        .unwrap();
    let proposal_transaction_cookie = governance_test
        .with_mint_tokens_transaction(
            &governed_mint_cookie,
            &mut proposal_cookie,
            &token_owner_record_cookie,
            0,
            None,
        )
        .await
        .unwrap();
    governance_test
        .sign_off_proposal(&proposal_cookie, &signatory_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    let err = governance_test
        .execute_proposal_transaction(&proposal_cookie, &proposal_transaction_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::CannotExecuteTransactionWithinHoldUpTime.into()
    );
}