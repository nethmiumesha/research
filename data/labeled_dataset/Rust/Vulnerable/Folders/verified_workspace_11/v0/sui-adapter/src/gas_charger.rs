pub use checked::*;
#[sui_macros::with_checked_arithmetic]
pub mod checked {
    use crate::sui_types::gas::SuiGasStatusAPI;
    use crate::temporary_store::TemporaryStore;
    use sui_protocol_config::ProtocolConfig;
    use sui_types::gas::{deduct_gas, GasCostSummary, SuiGasStatus};
    use sui_types::gas_model::gas_predicates::dont_charge_budget_on_storage_oog;
    use sui_types::{
        base_types::{ObjectID, ObjectRef},
        digests::TransactionDigest,
        error::ExecutionError,
        gas_model::tables::GasStatus,
        is_system_package,
        object::Data,
        storage::{DeleteKindWithOldVersion, WriteKind},
    };
    use tracing::trace;
    #[derive(Debug)]
    pub struct GasCharger {
        tx_digest: TransactionDigest,
        gas_model_version: u64,
        gas_coins: Vec<ObjectRef>,
        smashed_gas_coin: Option<ObjectID>,
        gas_status: SuiGasStatus,
    }
    impl GasCharger {
        pub fn new(
            tx_digest: TransactionDigest,
            gas_coins: Vec<ObjectRef>,
            gas_status: SuiGasStatus,
            protocol_config: &ProtocolConfig,
        ) -> Self {
            let gas_model_version = protocol_config.gas_model_version();
            Self {
                tx_digest,
                gas_model_version,
                gas_coins,
                smashed_gas_coin: None,
                gas_status,
            }
        }
        pub fn new_unmetered(tx_digest: TransactionDigest) -> Self {
            Self {
                tx_digest,
                gas_model_version: 6,
                gas_coins: vec![],
                smashed_gas_coin: None,
                gas_status: SuiGasStatus::new_unmetered(),
            }
        }
        pub(crate) fn gas_coins(&self) -> &[ObjectRef] {
            &self.gas_coins
        }
        pub fn gas_coin(&self) -> Option<ObjectID> {
            self.smashed_gas_coin
        }
        pub fn gas_budget(&self) -> u64 {
            self.gas_status.gas_budget()
        }
        pub fn unmetered_storage_rebate(&self) -> u64 {
            self.gas_status.unmetered_storage_rebate()
        }
        pub fn no_charges(&self) -> bool {
            self.gas_status.gas_used() == 0
                && self.gas_status.storage_rebate() == 0
                && self.gas_status.storage_gas_units() == 0
        }
        pub fn is_unmetered(&self) -> bool {
            self.gas_status.is_unmetered()
        }
        pub fn move_gas_status(&self) -> &GasStatus {
            self.gas_status.move_gas_status()
        }
        pub fn move_gas_status_mut(&mut self) -> &mut GasStatus {
            self.gas_status.move_gas_status_mut()
        }
        pub fn into_gas_status(self) -> SuiGasStatus {
            self.gas_status
        }
        pub fn summary(&self) -> GasCostSummary {
            self.gas_status.summary()
        }
        pub fn smash_gas(&mut self, temporary_store: &mut TemporaryStore<'_>) {
            let gas_coin_count = self.gas_coins.len();
            if gas_coin_count == 0 || (gas_coin_count == 1 && self.gas_coins[0].0 == ObjectID::ZERO)
            {
                return;
            }
            let gas_coin_id = self.gas_coins[0].0;
            self.smashed_gas_coin = Some(gas_coin_id);
            if gas_coin_count == 1 {
                return;
            }
            let new_balance = self
                .gas_coins
                .iter()
                .map(|obj_ref| {
                    let obj = temporary_store.objects().get(&obj_ref.0).unwrap();
                    let Data::Move(move_obj) = &obj.data else {
                        return Err(ExecutionError::invariant_violation(
                            "Provided non-gas coin object as input for gas!",
                        ));
                    };
                    if !move_obj.type_().is_gas_coin() {
                        return Err(ExecutionError::invariant_violation(
                            "Provided non-gas coin object as input for gas!",
                        ));
                    }
                    Ok(move_obj.get_coin_value_unsafe())
                })
                .collect::<Result<Vec<u64>, ExecutionError>>()
                .unwrap_or_else(|_| {
                    panic!(
                        "Invariant violation: non-gas coin object as input for gas in txn {}",
                        self.tx_digest
                    )
                })
                .iter()
                .sum();
            let mut primary_gas_object = temporary_store
                .objects()
                .get(&gas_coin_id)
                .unwrap_or_else(|| {
                    panic!(
                        "Invariant violation: gas coin not found in store in txn {}",
                        self.tx_digest
                    )
                })
                .clone();
            for (id, version, _digest) in &self.gas_coins[1..] {
                debug_assert_ne!(*id, primary_gas_object.id());
                temporary_store.delete_object(id, DeleteKindWithOldVersion::Normal(*version));
            }
            primary_gas_object
                .data
                .try_as_move_mut()
                .unwrap_or_else(|| {
                    panic!(
                        "Invariant violation: invalid coin object in txn {}",
                        self.tx_digest
                    )
                })
                .set_coin_value_unsafe(new_balance);
            temporary_store.write_object(primary_gas_object, WriteKind::Mutate);
        }
        pub fn track_storage_mutation(
            &mut self,
            object_id: ObjectID,
            new_size: usize,
            storage_rebate: u64,
        ) -> u64 {
            self.gas_status
                .track_storage_mutation(object_id, new_size, storage_rebate)
        }
        pub fn reset_storage_cost_and_rebate(&mut self) {
            self.gas_status.reset_storage_cost_and_rebate();
        }
        pub fn charge_publish_package(&mut self, size: usize) -> Result<(), ExecutionError> {
            self.gas_status.charge_publish_package(size)
        }
        pub fn charge_input_objects(
            &mut self,
            temporary_store: &TemporaryStore<'_>,
        ) -> Result<(), ExecutionError> {
            let objects = temporary_store.objects();
            let _object_count = objects.len();
            let total_size = temporary_store
                .objects()
                .iter()
                .filter(|(id, _)| !is_system_package(**id))
                .map(|(_, obj)| obj.object_size_for_gas_metering())
                .sum();
            self.gas_status.charge_storage_read(total_size)
        }
        pub fn reset(&mut self, temporary_store: &mut TemporaryStore<'_>) {
            temporary_store.drop_writes();
            self.gas_status.reset_storage_cost_and_rebate();
            self.smash_gas(temporary_store);
        }
        pub fn charge_gas<T>(
            &mut self,
            temporary_store: &mut TemporaryStore<'_>,
            execution_result: &mut Result<T, ExecutionError>,
        ) -> GasCostSummary {
            debug_assert!(self.gas_status.storage_rebate() == 0);
            debug_assert!(self.gas_status.storage_gas_units() == 0);
            if self.smashed_gas_coin.is_some() {
                if let Err(err) = self.gas_status.bucketize_computation(None) {
                    if execution_result.is_ok() {
                        *execution_result = Err(err);
                    }
                }
                if execution_result.is_err() {
                    self.reset(temporary_store);
                }
            }
            temporary_store.ensure_gas_and_input_mutated(self);
            temporary_store.collect_storage_and_rebate(self);
            if self.smashed_gas_coin.is_some() {
                #[skip_checked_arithmetic]
                trace!(target: "replay_gas_info", "Gas smashing has occurred for this transaction");
            }
            if let Some(gas_object_id) = self.smashed_gas_coin {
                if dont_charge_budget_on_storage_oog(self.gas_model_version) {
                    self.handle_storage_and_rebate_v2(temporary_store, execution_result)
                } else {
                    self.handle_storage_and_rebate_v1(temporary_store, execution_result)
                }
                let cost_summary = self.gas_status.summary();
                let gas_used = cost_summary.net_gas_usage();
                let mut gas_object = temporary_store.read_object(&gas_object_id).unwrap().clone();
                deduct_gas(&mut gas_object, gas_used);
                #[skip_checked_arithmetic]
                trace!(gas_used, gas_obj_id =? gas_object.id(), gas_obj_ver =? gas_object.version(), "Updated gas object");
                temporary_store.write_object(gas_object, WriteKind::Mutate);
                cost_summary
            } else {
                GasCostSummary::default()
            }
        }
        fn handle_storage_and_rebate_v1<T>(
            &mut self,
            temporary_store: &mut TemporaryStore<'_>,
            execution_result: &mut Result<T, ExecutionError>,
        ) {
            if let Err(err) = self.gas_status.charge_storage_and_rebate() {
                self.reset(temporary_store);
                self.gas_status.adjust_computation_on_out_of_gas();
                temporary_store.ensure_gas_and_input_mutated(self);
                temporary_store.collect_rebate(self);
                if execution_result.is_ok() {
                    *execution_result = Err(err);
                }
            }
        }
        fn handle_storage_and_rebate_v2<T>(
            &mut self,
            temporary_store: &mut TemporaryStore<'_>,
            execution_result: &mut Result<T, ExecutionError>,
        ) {
            if let Err(err) = self.gas_status.charge_storage_and_rebate() {
                self.reset(temporary_store);
                temporary_store.ensure_gas_and_input_mutated(self);
                temporary_store.collect_storage_and_rebate(self);
                if let Err(err) = self.gas_status.charge_storage_and_rebate() {
                    self.reset(temporary_store);
                    self.gas_status.adjust_computation_on_out_of_gas();
                    temporary_store.ensure_gas_and_input_mutated(self);
                    temporary_store.collect_rebate(self);
                    if execution_result.is_ok() {
                        *execution_result = Err(err);
                    }
                } else if execution_result.is_ok() {
                    *execution_result = Err(err);
                }
            }
        }
    }
}