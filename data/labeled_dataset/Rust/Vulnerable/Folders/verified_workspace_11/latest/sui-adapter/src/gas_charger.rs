pub use checked::*;
#[sui_macros::with_checked_arithmetic]
pub mod checked {
    use crate::sui_types::gas::SuiGasStatusAPI;
    use crate::temporary_store::TemporaryStore;
    use either::Either;
    use sui_protocol_config::ProtocolConfig;
    use sui_types::deny_list_v2::CONFIG_SETTING_DYNAMIC_FIELD_SIZE_FOR_GAS;
    use sui_types::gas::{GasCostSummary, SuiGasStatus, deduct_gas};
    use sui_types::gas_model::gas_predicates::{
        charge_upgrades, dont_charge_budget_on_storage_oog,
    };
    use sui_types::{
        accumulator_event::AccumulatorEvent,
        base_types::{ObjectID, ObjectRef, SuiAddress},
        digests::TransactionDigest,
        error::ExecutionError,
        gas_model::tables::GasStatus,
        is_system_package,
        object::Data,
    };
    use tracing::trace;
    #[derive(Debug)]
    pub struct GasCharger {
        tx_digest: TransactionDigest,
        gas_model_version: u64,
        payment_method: PaymentMethod,
        smashed_gas_coin: Option<ObjectID>,
        gas_status: SuiGasStatus,
    }
    #[derive(Debug)]
    pub enum PaymentMethod {
        Unmetered,
        Coins(Vec<ObjectRef>),
        AddressBalance(SuiAddress),
    }
    impl PaymentMethod {
        pub fn is_unmetered(&self) -> bool {
            matches!(self, PaymentMethod::Unmetered)
        }
        pub fn is_address_balance(&self) -> bool {
            matches!(self, PaymentMethod::AddressBalance(_))
        }
        pub fn is_coins(&self) -> bool {
            matches!(self, PaymentMethod::Coins(_))
        }
    }
    impl GasCharger {
        pub fn new(
            tx_digest: TransactionDigest,
            payment_method: PaymentMethod,
            gas_status: SuiGasStatus,
            protocol_config: &ProtocolConfig,
        ) -> Self {
            let gas_model_version = protocol_config.gas_model_version();
            Self {
                tx_digest,
                gas_model_version,
                payment_method,
                smashed_gas_coin: None,
                gas_status,
            }
        }
        pub fn new_unmetered(tx_digest: TransactionDigest) -> Self {
            Self {
                tx_digest,
                gas_model_version: 6,
                payment_method: PaymentMethod::Unmetered,
                smashed_gas_coin: None,
                gas_status: SuiGasStatus::new_unmetered(),
            }
        }
        pub(crate) fn gas_coins(&self) -> impl Iterator<Item = &'_ ObjectRef> {
            match &self.payment_method {
                PaymentMethod::Coins(gas_coins) => Either::Left(gas_coins.iter()),
                PaymentMethod::AddressBalance(_) | PaymentMethod::Unmetered => {
                    Either::Right(std::iter::empty())
                }
            }
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
            if let PaymentMethod::Coins(gas_coins) = &mut self.payment_method {
                let gas_coin_count = gas_coins.len();
                if gas_coin_count == 0 || (gas_coin_count == 1 && gas_coins[0].0 == ObjectID::ZERO)
                {
                    return;
                }
                let gas_coin_id = gas_coins[0].0;
                self.smashed_gas_coin = Some(gas_coin_id);
                if gas_coin_count == 1 {
                    return;
                }
                let new_balance = gas_coins
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
                for (id, _version, _digest) in &gas_coins[1..] {
                    debug_assert_ne!(*id, primary_gas_object.id());
                    temporary_store.delete_input_object(id);
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
                temporary_store.mutate_input_object(primary_gas_object);
            }
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
        pub fn charge_upgrade_package(&mut self, size: usize) -> Result<(), ExecutionError> {
            if charge_upgrades(self.gas_model_version) {
                self.gas_status.charge_publish_package(size)
            } else {
                Ok(())
            }
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
        pub fn charge_coin_transfers(
            &mut self,
            protocol_config: &ProtocolConfig,
            num_non_gas_coin_owners: u64,
        ) -> Result<(), ExecutionError> {
            let bytes_read_per_owner = CONFIG_SETTING_DYNAMIC_FIELD_SIZE_FOR_GAS;
            let cost_per_byte =
                protocol_config.dynamic_field_borrow_child_object_type_cost_per_byte() as usize;
            let cost_per_owner = bytes_read_per_owner * cost_per_byte;
            let owner_cost = cost_per_owner * (num_non_gas_coin_owners as usize);
            self.gas_status.charge_storage_read(owner_cost)
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
            if self.smashed_gas_coin.is_some() || self.payment_method.is_address_balance() {
                let is_move_abort = execution_result
                    .as_ref()
                    .err()
                    .map(|err| {
                        matches!(
                            err.kind(),
                            sui_types::execution_status::ExecutionErrorKind::MoveAbort(_, _)
                        )
                    })
                    .unwrap_or(false);
                if let Err(err) = self.gas_status.bucketize_computation(Some(is_move_abort))
                    && execution_result.is_ok()
                {
                    *execution_result = Err(err);
                }
                if execution_result.is_err() {
                    self.reset(temporary_store);
                }
            }
            temporary_store.ensure_active_inputs_mutated();
            temporary_store.collect_storage_and_rebate(self);
            if self.smashed_gas_coin.is_some() {
                #[skip_checked_arithmetic]
                trace!(target: "replay_gas_info", "Gas smashing has occurred for this transaction");
            }
            if self.payment_method.is_unmetered() {
                return GasCostSummary::default();
            }
            if execution_result
                .as_ref()
                .err()
                .map(|err| {
                    matches!(
                        err.kind(),
                        sui_types::execution_status::ExecutionErrorKind::InsufficientFundsForWithdraw
                    )
                })
                .unwrap_or(false)
                && self.payment_method.is_address_balance() {
                    return GasCostSummary::default();
            }
            self.compute_storage_and_rebate(temporary_store, execution_result);
            let cost_summary = self.gas_status.summary();
            let net_change = cost_summary.net_gas_usage();
            match self.payment_method {
                PaymentMethod::AddressBalance(payer_address) => {
                    if net_change != 0 {
                        let balance_type = sui_types::balance::Balance::type_tag(
                            sui_types::gas_coin::GAS::type_tag(),
                        );
                        let accumulator_event = AccumulatorEvent::from_balance_change(
                            payer_address,
                            balance_type,
                            net_change,
                        )
                        .expect("Failed to create accumulator event for gas balance");
                        temporary_store.add_accumulator_event(accumulator_event);
                    }
                    cost_summary
                }
                PaymentMethod::Coins(_) => {
                    let gas_object_id = self.smashed_gas_coin.unwrap();
                    let mut gas_object =
                        temporary_store.read_object(&gas_object_id).unwrap().clone();
                    deduct_gas(&mut gas_object, net_change);
                    #[skip_checked_arithmetic]
                    trace!(net_change, gas_obj_id =? gas_object.id(), gas_obj_ver =? gas_object.version(), "Updated gas object");
                    temporary_store.mutate_input_object(gas_object);
                    cost_summary
                }
                PaymentMethod::Unmetered => unreachable!(),
            }
        }
        fn compute_storage_and_rebate<T>(
            &mut self,
            temporary_store: &mut TemporaryStore<'_>,
            execution_result: &mut Result<T, ExecutionError>,
        ) {
            if dont_charge_budget_on_storage_oog(self.gas_model_version) {
                self.handle_storage_and_rebate_v2(temporary_store, execution_result)
            } else {
                self.handle_storage_and_rebate_v1(temporary_store, execution_result)
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
                temporary_store.ensure_active_inputs_mutated();
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
                temporary_store.ensure_active_inputs_mutated();
                temporary_store.collect_storage_and_rebate(self);
                if let Err(err) = self.gas_status.charge_storage_and_rebate() {
                    self.reset(temporary_store);
                    self.gas_status.adjust_computation_on_out_of_gas();
                    temporary_store.ensure_active_inputs_mutated();
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