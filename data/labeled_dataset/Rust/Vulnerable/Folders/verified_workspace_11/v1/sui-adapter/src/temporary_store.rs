use crate::gas_charger::GasCharger;
use parking_lot::RwLock;
use std::collections::{BTreeMap, BTreeSet, HashSet};
use sui_protocol_config::ProtocolConfig;
use sui_types::base_types::VersionDigest;
use sui_types::committee::EpochId;
use sui_types::digests::ObjectDigest;
use sui_types::effects::{TransactionEffects, TransactionEvents};
use sui_types::execution::{
    DynamicallyLoadedObjectMetadata, ExecutionResults, ExecutionResultsV2, SharedInput,
};
use sui_types::execution_status::ExecutionStatus;
use sui_types::inner_temporary_store::InnerTemporaryStore;
use sui_types::layout_resolver::LayoutResolver;
use sui_types::storage::{BackingStore, DenyListResult, PackageObject};
use sui_types::sui_system_state::{get_sui_system_state_wrapper, AdvanceEpochParams};
use sui_types::{
    base_types::{ObjectID, ObjectRef, SequenceNumber, SuiAddress, TransactionDigest},
    effects::EffectsObjectChange,
    error::{ExecutionError, SuiResult},
    gas::GasCostSummary,
    object::Object,
    object::Owner,
    storage::{BackingPackageStore, ChildObjectResolver, ParentSync, Storage},
    transaction::InputObjects,
    TypeTag,
};
use sui_types::{is_system_package, SUI_SYSTEM_STATE_OBJECT_ID};
pub struct TemporaryStore<'backing> {
    store: &'backing dyn BackingStore,
    tx_digest: TransactionDigest,
    input_objects: BTreeMap<ObjectID, Object>,
    deleted_consensus_objects: BTreeMap<ObjectID, SequenceNumber>,
    lamport_timestamp: SequenceNumber,
    mutable_input_refs: BTreeMap<ObjectID, (VersionDigest, Owner)>,
    execution_results: ExecutionResultsV2,
    loaded_runtime_objects: BTreeMap<ObjectID, DynamicallyLoadedObjectMetadata>,
    protocol_config: ProtocolConfig,
    runtime_packages_loaded_from_db: RwLock<BTreeMap<ObjectID, PackageObject>>,
    receiving_objects: Vec<ObjectRef>,
}
impl<'backing> TemporaryStore<'backing> {
    pub fn new(
        store: &'backing dyn BackingStore,
        input_objects: InputObjects,
        receiving_objects: Vec<ObjectRef>,
        tx_digest: TransactionDigest,
        protocol_config: &ProtocolConfig,
    ) -> Self {
        let mutable_input_refs = input_objects.exclusive_mutable_inputs();
        let lamport_timestamp = input_objects.lamport_timestamp(&receiving_objects);
        let deleted_consensus_objects = input_objects.consensus_stream_ended_objects();
        let objects = input_objects.into_object_map();
        Self {
            store,
            tx_digest,
            input_objects: objects,
            deleted_consensus_objects,
            lamport_timestamp,
            mutable_input_refs,
            execution_results: ExecutionResultsV2::default(),
            protocol_config: protocol_config.clone(),
            loaded_runtime_objects: BTreeMap::new(),
            runtime_packages_loaded_from_db: RwLock::new(BTreeMap::new()),
            receiving_objects,
        }
    }
    pub fn objects(&self) -> &BTreeMap<ObjectID, Object> {
        &self.input_objects
    }
    pub fn update_object_version_and_prev_tx(&mut self) {
        self.execution_results.update_version_and_previous_tx(
            self.lamport_timestamp,
            self.tx_digest,
            &self.input_objects,
            false,
        );
        #[cfg(debug_assertions)]
        {
            self.check_invariants();
        }
    }
    pub fn into_inner(self) -> InnerTemporaryStore {
        let results = self.execution_results;
        InnerTemporaryStore {
            input_objects: self.input_objects,
            stream_ended_consensus_objects: self.deleted_consensus_objects,
            mutable_inputs: self.mutable_input_refs,
            written: results.written_objects,
            events: TransactionEvents {
                data: results.user_events,
            },
            accumulator_events: vec![],
            loaded_runtime_objects: self.loaded_runtime_objects,
            runtime_packages_loaded_from_db: self.runtime_packages_loaded_from_db.into_inner(),
            lamport_version: self.lamport_timestamp,
            binary_config: self.protocol_config.binary_config(None),
            accumulator_running_max_withdraws: BTreeMap::new(),
        }
    }
    pub(crate) fn ensure_active_inputs_mutated(&mut self) {
        let mut to_be_updated = vec![];
        for id in self.mutable_input_refs.keys() {
            if !self.execution_results.modified_objects.contains(id) {
                to_be_updated.push(self.input_objects[id].clone());
            }
        }
        for object in to_be_updated {
            self.mutate_input_object(object.clone());
        }
    }
    fn get_object_changes(&self) -> BTreeMap<ObjectID, EffectsObjectChange> {
        let results = &self.execution_results;
        let all_ids = results
            .created_object_ids
            .iter()
            .chain(&results.deleted_object_ids)
            .chain(&results.modified_objects)
            .chain(results.written_objects.keys())
            .collect::<BTreeSet<_>>();
        all_ids
            .into_iter()
            .map(|id| {
                (
                    *id,
                    EffectsObjectChange::new(
                        self.get_object_modified_at(id)
                            .map(|metadata| ((metadata.version, metadata.digest), metadata.owner)),
                        results.written_objects.get(id),
                        results.created_object_ids.contains(id),
                        results.deleted_object_ids.contains(id),
                    ),
                )
            })
            .collect()
    }
    pub fn into_effects(
        mut self,
        shared_object_refs: Vec<SharedInput>,
        transaction_digest: &TransactionDigest,
        mut transaction_dependencies: BTreeSet<TransactionDigest>,
        gas_cost_summary: GasCostSummary,
        status: ExecutionStatus,
        gas_charger: &mut GasCharger,
        epoch: EpochId,
    ) -> (InnerTemporaryStore, TransactionEffects) {
        self.update_object_version_and_prev_tx();
        for (id, expected_version, expected_digest) in &self.receiving_objects {
            if let Some(obj_meta) = self.loaded_runtime_objects.get(id) {
                let loaded_via_receive = obj_meta.version == *expected_version
                    && obj_meta.digest == *expected_digest
                    && obj_meta.owner.is_address_owned();
                if loaded_via_receive {
                    transaction_dependencies.insert(obj_meta.previous_transaction);
                }
            }
        }
        if self.protocol_config.enable_effects_v2() {
            self.into_effects_v2(
                shared_object_refs,
                transaction_digest,
                transaction_dependencies,
                gas_cost_summary,
                status,
                gas_charger,
                epoch,
            )
        } else {
            let shared_object_refs = shared_object_refs
                .into_iter()
                .map(|shared_input| match shared_input {
                    SharedInput::Existing(oref) => oref,
                    SharedInput::ConsensusStreamEnded(_) => {
                        unreachable!("Shared object deletion not supported in effects v1")
                    }
                    SharedInput::Cancelled(_) => {
                        unreachable!("Per object congestion control not supported in effects v1.")
                    }
                })
                .collect();
            self.into_effects_v1(
                shared_object_refs,
                transaction_digest,
                transaction_dependencies,
                gas_cost_summary,
                status,
                gas_charger,
                epoch,
            )
        }
    }
    fn into_effects_v1(
        self,
        shared_object_refs: Vec<ObjectRef>,
        transaction_digest: &TransactionDigest,
        transaction_dependencies: BTreeSet<TransactionDigest>,
        gas_cost_summary: GasCostSummary,
        status: ExecutionStatus,
        gas_charger: &mut GasCharger,
        epoch: EpochId,
    ) -> (InnerTemporaryStore, TransactionEffects) {
        let updated_gas_object_info = if let Some(coin_id) = gas_charger.gas_coin() {
            let object = &self.execution_results.written_objects[&coin_id];
            (object.compute_object_reference(), object.owner.clone())
        } else {
            (
                (ObjectID::ZERO, SequenceNumber::default(), ObjectDigest::MIN),
                Owner::AddressOwner(SuiAddress::default()),
            )
        };
        let lampot_version = self.lamport_timestamp;
        let mut created = vec![];
        let mut mutated = vec![];
        let mut unwrapped = vec![];
        let mut deleted = vec![];
        let mut unwrapped_then_deleted = vec![];
        let mut wrapped = vec![];
        let mut modified_at_versions = vec![];
        let mut deleted_at_versions = vec![];
        self.execution_results
            .written_objects
            .iter()
            .for_each(|(id, object)| {
                let object_ref = object.compute_object_reference();
                let owner = object.owner.clone();
                if let Some(old_object_meta) = self.get_object_modified_at(id) {
                    modified_at_versions.push((*id, old_object_meta.version));
                    mutated.push((object_ref, owner));
                } else if self.execution_results.created_object_ids.contains(id) {
                    created.push((object_ref, owner));
                } else {
                    unwrapped.push((object_ref, owner));
                }
            });
        self.execution_results
            .modified_objects
            .iter()
            .filter(|id| !self.execution_results.written_objects.contains_key(id))
            .for_each(|id| {
                let old_object_meta = self.get_object_modified_at(id).unwrap();
                deleted_at_versions.push((*id, old_object_meta.version));
                if self.execution_results.deleted_object_ids.contains(id) {
                    deleted.push((*id, lampot_version, ObjectDigest::OBJECT_DIGEST_DELETED));
                } else {
                    wrapped.push((*id, lampot_version, ObjectDigest::OBJECT_DIGEST_WRAPPED));
                }
            });
        self.execution_results
            .deleted_object_ids
            .iter()
            .filter(|id| !self.execution_results.modified_objects.contains(id))
            .for_each(|id| {
                unwrapped_then_deleted.push((
                    *id,
                    lampot_version,
                    ObjectDigest::OBJECT_DIGEST_DELETED,
                ));
            });
        modified_at_versions.extend(deleted_at_versions);
        let inner = self.into_inner();
        let effects = TransactionEffects::new_from_execution_v1(
            status,
            epoch,
            gas_cost_summary,
            modified_at_versions,
            shared_object_refs,
            *transaction_digest,
            created,
            mutated,
            unwrapped,
            deleted,
            unwrapped_then_deleted,
            wrapped,
            updated_gas_object_info,
            if inner.events.data.is_empty() {
                None
            } else {
                Some(inner.events.digest())
            },
            transaction_dependencies.into_iter().collect(),
        );
        (inner, effects)
    }
    fn into_effects_v2(
        self,
        shared_object_refs: Vec<SharedInput>,
        transaction_digest: &TransactionDigest,
        transaction_dependencies: BTreeSet<TransactionDigest>,
        gas_cost_summary: GasCostSummary,
        status: ExecutionStatus,
        gas_charger: &mut GasCharger,
        epoch: EpochId,
    ) -> (InnerTemporaryStore, TransactionEffects) {
        let gas_coin = gas_charger.gas_coin();
        let object_changes = self.get_object_changes();
        let lamport_version = self.lamport_timestamp;
        let inner = self.into_inner();
        let effects = TransactionEffects::new_from_execution_v2(
            status,
            epoch,
            gas_cost_summary,
            shared_object_refs,
            BTreeSet::new(),
            *transaction_digest,
            lamport_version,
            object_changes,
            gas_coin,
            if inner.events.data.is_empty() {
                None
            } else {
                Some(inner.events.digest())
            },
            transaction_dependencies.into_iter().collect(),
        );
        (inner, effects)
    }
    #[cfg(debug_assertions)]
    fn check_invariants(&self) {
        debug_assert!(
            {
                self.execution_results
                    .written_objects
                    .keys()
                    .all(|id| !self.execution_results.deleted_object_ids.contains(id))
            },
            "Object both written and deleted."
        );
        debug_assert!(
            {
                self.mutable_input_refs
                    .keys()
                    .all(|id| self.execution_results.modified_objects.contains(id))
            },
            "Mutable input not modified."
        );
        debug_assert!(
            {
                self.execution_results
                    .written_objects
                    .values()
                    .all(|obj| obj.previous_transaction == self.tx_digest)
            },
            "Object previous transaction not properly set",
        );
    }
    pub fn mutate_input_object(&mut self, object: Object) {
        let id = object.id();
        self.execution_results.modified_objects.insert(id);
        self.execution_results.written_objects.insert(id, object);
    }
    pub fn mutate_child_object(&mut self, old_object: Object, new_object: Object) {
        let id = new_object.id();
        let old_ref = old_object.compute_object_reference();
        debug_assert_eq!(old_ref.0, id);
        self.loaded_runtime_objects.insert(
            id,
            DynamicallyLoadedObjectMetadata {
                version: old_ref.1,
                digest: old_ref.2,
                owner: old_object.owner.clone(),
                storage_rebate: old_object.storage_rebate,
                previous_transaction: old_object.previous_transaction,
            },
        );
        self.execution_results.modified_objects.insert(id);
        self.execution_results
            .written_objects
            .insert(id, new_object);
    }
    pub fn upgrade_system_package(&mut self, package: Object) {
        let id = package.id();
        assert!(package.is_package() && is_system_package(id));
        self.execution_results.modified_objects.insert(id);
        self.execution_results.written_objects.insert(id, package);
    }
    pub fn create_object(&mut self, object: Object) {
        debug_assert!(
            object.is_immutable() || object.version() == SequenceNumber::MIN,
            "Created mutable objects should not have a version set",
        );
        let id = object.id();
        self.execution_results.created_object_ids.insert(id);
        self.execution_results.written_objects.insert(id, object);
    }
    pub fn delete_input_object(&mut self, id: &ObjectID) {
        debug_assert!(!self.execution_results.written_objects.contains_key(id));
        self.execution_results.modified_objects.insert(*id);
        self.execution_results.deleted_object_ids.insert(*id);
    }
    pub fn drop_writes(&mut self) {
        self.execution_results.drop_writes();
    }
    pub fn read_object(&self, id: &ObjectID) -> Option<&Object> {
        debug_assert!(!self.execution_results.deleted_object_ids.contains(id));
        self.execution_results
            .written_objects
            .get(id)
            .or_else(|| self.input_objects.get(id))
    }
    pub fn save_loaded_runtime_objects(
        &mut self,
        loaded_runtime_objects: BTreeMap<ObjectID, DynamicallyLoadedObjectMetadata>,
    ) {
        #[cfg(debug_assertions)]
        {
            for (id, v1) in &loaded_runtime_objects {
                if let Some(v2) = self.loaded_runtime_objects.get(id) {
                    assert_eq!(v1, v2);
                }
            }
            for (id, v1) in &self.loaded_runtime_objects {
                if let Some(v2) = loaded_runtime_objects.get(id) {
                    assert_eq!(v1, v2);
                }
            }
        }
        self.loaded_runtime_objects.extend(loaded_runtime_objects);
    }
    pub fn estimate_effects_size_upperbound(&self) -> usize {
        if self.protocol_config.enable_effects_v2() {
            TransactionEffects::estimate_effects_size_upperbound_v2(
                self.execution_results.written_objects.len(),
                self.execution_results.modified_objects.len(),
                self.input_objects.len(),
            )
        } else {
            let num_deletes = self.execution_results.deleted_object_ids.len()
                + self
                    .execution_results
                    .modified_objects
                    .iter()
                    .filter(|id| {
                        !self.execution_results.written_objects.contains_key(id)
                            && !self.execution_results.deleted_object_ids.contains(id)
                    })
                    .count();
            TransactionEffects::estimate_effects_size_upperbound_v1(
                self.execution_results.written_objects.len(),
                self.mutable_input_refs.len(),
                num_deletes,
                self.input_objects.len(),
            )
        }
    }
    pub fn written_objects_size(&self) -> usize {
        self.execution_results
            .written_objects
            .values()
            .fold(0, |sum, obj| sum + obj.object_size_for_gas_metering())
    }
    pub fn conserve_unmetered_storage_rebate(&mut self, unmetered_storage_rebate: u64) {
        if unmetered_storage_rebate == 0 {
            return;
        }
        tracing::debug!(
            "Amount of unmetered storage rebate from system tx: {:?}",
            unmetered_storage_rebate
        );
        let mut system_state_wrapper = self
            .read_object(&SUI_SYSTEM_STATE_OBJECT_ID)
            .expect("0x5 object must be muated in system tx with unmetered storage rebate")
            .clone();
        assert_eq!(system_state_wrapper.storage_rebate, 0);
        system_state_wrapper.storage_rebate = unmetered_storage_rebate;
        self.mutate_input_object(system_state_wrapper);
    }
    fn get_object_modified_at(
        &self,
        object_id: &ObjectID,
    ) -> Option<DynamicallyLoadedObjectMetadata> {
        if self.execution_results.modified_objects.contains(object_id) {
            Some(
                self.mutable_input_refs
                    .get(object_id)
                    .map(
                        |((version, digest), owner)| DynamicallyLoadedObjectMetadata {
                            version: *version,
                            digest: *digest,
                            owner: owner.clone(),
                            storage_rebate: self.input_objects[object_id].storage_rebate,
                            previous_transaction: self.input_objects[object_id]
                                .previous_transaction,
                        },
                    )
                    .or_else(|| self.loaded_runtime_objects.get(object_id).cloned())
                    .unwrap_or_else(|| {
                        debug_assert!(is_system_package(*object_id));
                        let obj = self.store.get_object(object_id).unwrap();
                        DynamicallyLoadedObjectMetadata {
                            version: obj.version(),
                            digest: obj.digest(),
                            owner: obj.owner.clone(),
                            storage_rebate: obj.storage_rebate,
                            previous_transaction: obj.previous_transaction,
                        }
                    }),
            )
        } else {
            None
        }
    }
}
impl TemporaryStore<'_> {
    fn get_objects_to_authenticate(
        &self,
        sender: &SuiAddress,
        gas_charger: &mut GasCharger,
        is_epoch_change: bool,
    ) -> SuiResult<(Vec<ObjectID>, HashSet<ObjectID>)> {
        let gas_objs: HashSet<&ObjectID> = gas_charger.gas_coins().iter().map(|g| &g.0).collect();
        let mut objs_to_authenticate = Vec::new();
        let mut authenticated_objs = HashSet::new();
        for (id, obj) in &self.input_objects {
            if gas_objs.contains(id) {
                continue;
            }
            match &obj.owner {
                Owner::AddressOwner(a) => {
                    assert!(sender == a, "Input object not owned by sender");
                    authenticated_objs.insert(*id);
                }
                Owner::Shared { .. } => {
                    authenticated_objs.insert(*id);
                }
                Owner::Immutable => {
                }
                Owner::ObjectOwner(_parent) => {
                    unreachable!("Input objects must be address owned, shared, or immutable")
                }
                Owner::ConsensusAddressOwner { .. } => {
                    unimplemented!(
                        "ConsensusAddressOwner does not exist for this execution version"
                    )
                }
            }
        }
        for id in &self.execution_results.modified_objects {
            if authenticated_objs.contains(id) || gas_objs.contains(id) {
                continue;
            }
            let old_obj = self.store.get_object(id).unwrap_or_else(|| {
                panic!("Modified object must exist in the store: ID = {:?}", id)
            });
            match &old_obj.owner {
                Owner::ObjectOwner(_) | Owner::AddressOwner(_) => {
                    objs_to_authenticate.push(*id);
                }
                Owner::Shared { .. } => {
                    unreachable!("Should already be in authenticated_objs")
                }
                Owner::Immutable => {
                    assert!(is_epoch_change, "Immutable objects cannot be written, except for Sui Framework/Move stdlib upgrades at epoch change boundaries");
                    assert!(
                        is_system_package(*id),
                        "Only system packages can be upgraded"
                    );
                }
                Owner::ConsensusAddressOwner { .. } => {
                    unimplemented!(
                        "ConsensusAddressOwner does not exist for this execution version"
                    )
                }
            }
        }
        Ok((objs_to_authenticate, authenticated_objs))
    }
    pub fn check_ownership_invariants(
        &self,
        sender: &SuiAddress,
        gas_charger: &mut GasCharger,
        is_epoch_change: bool,
    ) -> SuiResult<()> {
        let (mut objects_to_authenticate, mut authenticated_objects) =
            self.get_objects_to_authenticate(sender, gas_charger, is_epoch_change)?;
        let mut covered = BTreeMap::new();
        while let Some(to_authenticate) = objects_to_authenticate.pop() {
            let Some(old_obj) = self.store.get_object(&to_authenticate) else {
                continue;
            };
            let parent = match &old_obj.owner {
                Owner::ObjectOwner(parent) | Owner::AddressOwner(parent) => ObjectID::from(*parent),
                owner => panic!(
                    "Unauthenticated root at {to_authenticate:?} with owner {owner:?}\n\
             Potentially covering objects in: {covered:#?}",
                ),
            };
            if authenticated_objects.contains(&parent) {
                authenticated_objects.insert(to_authenticate);
            } else if !covered.contains_key(&parent) {
                objects_to_authenticate.push(parent);
            }
            covered.insert(to_authenticate, parent);
        }
        Ok(())
    }
}
impl TemporaryStore<'_> {
    pub(crate) fn collect_storage_and_rebate(&mut self, gas_charger: &mut GasCharger) {
        let old_storage_rebates: Vec<_> = self
            .execution_results
            .written_objects
            .keys()
            .map(|object_id| {
                self.get_object_modified_at(object_id)
                    .map(|metadata| metadata.storage_rebate)
                    .unwrap_or_default()
            })
            .collect();
        for (object, old_storage_rebate) in self
            .execution_results
            .written_objects
            .values_mut()
            .zip(old_storage_rebates)
        {
            let new_object_size = object.object_size_for_gas_metering();
            let new_storage_rebate = gas_charger.track_storage_mutation(
                object.id(),
                new_object_size,
                old_storage_rebate,
            );
            object.storage_rebate = new_storage_rebate;
        }
        self.collect_rebate(gas_charger);
    }
    pub(crate) fn collect_rebate(&self, gas_charger: &mut GasCharger) {
        for object_id in &self.execution_results.modified_objects {
            if self
                .execution_results
                .written_objects
                .contains_key(object_id)
            {
                continue;
            }
            let storage_rebate = self
                .get_object_modified_at(object_id)
                .unwrap()
                .storage_rebate;
            gas_charger.track_storage_mutation(*object_id, 0, storage_rebate);
        }
    }
    pub fn check_execution_results_consistency(&self) -> Result<(), ExecutionError> {
        assert_invariant!(
            self.execution_results
                .created_object_ids
                .iter()
                .all(|id| !self.execution_results.deleted_object_ids.contains(id)
                    && !self.execution_results.modified_objects.contains(id)),
            "Created object IDs cannot also be deleted or modified"
        );
        assert_invariant!(
            self.execution_results.modified_objects.iter().all(|id| {
                self.mutable_input_refs.contains_key(id)
                    || self.loaded_runtime_objects.contains_key(id)
                    || is_system_package(*id)
            }),
            "A modified object must be either a mutable input, a loaded child object, or a system package"
        );
        Ok(())
    }
}
impl TemporaryStore<'_> {
    pub fn advance_epoch_safe_mode(
        &mut self,
        params: &AdvanceEpochParams,
        protocol_config: &ProtocolConfig,
    ) {
        let wrapper = get_sui_system_state_wrapper(self.store.as_object_store())
            .expect("System state wrapper object must exist");
        let (old_object, new_object) =
            wrapper.advance_epoch_safe_mode(params, self.store.as_object_store(), protocol_config);
        self.mutate_child_object(old_object, new_object);
    }
}
type ModifiedObjectInfo<'a> = (
    ObjectID,
    Option<DynamicallyLoadedObjectMetadata>,
    Option<&'a Object>,
);
impl TemporaryStore<'_> {
    fn get_input_sui(
        &self,
        id: &ObjectID,
        expected_version: SequenceNumber,
        layout_resolver: &mut impl LayoutResolver,
    ) -> Result<u64, ExecutionError> {
        if let Some(obj) = self.input_objects.get(id) {
            if obj.version() != expected_version {
                invariant_violation!(
                    "Version mismatching when resolving input object to check conservation--\
                     expected {}, got {}",
                    expected_version,
                    obj.version(),
                );
            }
            obj.get_total_sui(layout_resolver).map_err(|e| {
                make_invariant_violation!(
                    "Failed looking up input SUI in SUI conservation checking for input with \
                         type {:?}: {e:#?}",
                    obj.struct_tag(),
                )
            })
        } else {
            let Some(obj) = self.store.get_object_by_key(id, expected_version) else {
                invariant_violation!(
                    "Failed looking up dynamic field {id} in SUI conservation checking"
                );
            };
            obj.get_total_sui(layout_resolver).map_err(|e| {
                make_invariant_violation!(
                    "Failed looking up input SUI in SUI conservation checking for type \
                         {:?}: {e:#?}",
                    obj.struct_tag(),
                )
            })
        }
    }
    fn get_modified_objects(&self) -> Vec<ModifiedObjectInfo<'_>> {
        self.execution_results
            .modified_objects
            .iter()
            .map(|id| {
                let metadata = self.get_object_modified_at(id);
                let output = self.execution_results.written_objects.get(id);
                (*id, metadata, output)
            })
            .chain(
                self.execution_results
                    .written_objects
                    .iter()
                    .filter_map(|(id, object)| {
                        if self.execution_results.modified_objects.contains(id) {
                            None
                        } else {
                            Some((*id, None, Some(object)))
                        }
                    }),
            )
            .collect()
    }
    pub fn check_sui_conserved(
        &self,
        simple_conservation_checks: bool,
        gas_summary: &GasCostSummary,
    ) -> Result<(), ExecutionError> {
        if !simple_conservation_checks {
            return Ok(());
        }
        let mut total_input_rebate = 0;
        let mut total_output_rebate = 0;
        for (_, input, output) in self.get_modified_objects() {
            if let Some(input) = input {
                total_input_rebate += input.storage_rebate;
            }
            if let Some(object) = output {
                total_output_rebate += object.storage_rebate;
            }
        }
        if gas_summary.storage_cost == 0 {
            if total_input_rebate
                != total_output_rebate
                    + gas_summary.storage_rebate
                    + gas_summary.non_refundable_storage_fee
            {
                return Err(ExecutionError::invariant_violation(format!(
                    "SUI conservation failed -- no storage charges in gas summary \
                        and total storage input rebate {} not equal  \
                        to total storage output rebate {}",
                    total_input_rebate, total_output_rebate,
                )));
            }
        } else {
            if total_input_rebate
                != gas_summary.storage_rebate + gas_summary.non_refundable_storage_fee
            {
                return Err(ExecutionError::invariant_violation(format!(
                    "SUI conservation failed -- {} SUI in storage rebate field of input objects, \
                        {} SUI in tx storage rebate or tx non-refundable storage rebate",
                    total_input_rebate, gas_summary.non_refundable_storage_fee,
                )));
            }
            if gas_summary.storage_cost != total_output_rebate {
                return Err(ExecutionError::invariant_violation(format!(
                    "SUI conservation failed -- {} SUI charged for storage, \
                        {} SUI in storage rebate field of output objects",
                    gas_summary.storage_cost, total_output_rebate
                )));
            }
        }
        Ok(())
    }
    pub fn check_sui_conserved_expensive(
        &self,
        gas_summary: &GasCostSummary,
        advance_epoch_gas_summary: Option<(u64, u64)>,
        layout_resolver: &mut impl LayoutResolver,
    ) -> Result<(), ExecutionError> {
        let mut total_input_sui = 0;
        let mut total_output_sui = 0;
        for (id, input, output) in self.get_modified_objects() {
            if let Some(input) = input {
                total_input_sui += self.get_input_sui(&id, input.version, layout_resolver)?;
            }
            if let Some(object) = output {
                total_output_sui += object.get_total_sui(layout_resolver).map_err(|e| {
                    make_invariant_violation!(
                        "Failed looking up output SUI in SUI conservation checking for \
                         mutated type {:?}: {e:#?}",
                        object.struct_tag(),
                    )
                })?;
            }
        }
        total_output_sui += gas_summary.computation_cost + gas_summary.non_refundable_storage_fee;
        if let Some((epoch_fees, epoch_rebates)) = advance_epoch_gas_summary {
            total_input_sui += epoch_fees;
            total_output_sui += epoch_rebates;
        }
        if total_input_sui != total_output_sui {
            return Err(ExecutionError::invariant_violation(format!(
                "SUI conservation failed: input={}, output={}, \
                    this transaction either mints or burns SUI",
                total_input_sui, total_output_sui,
            )));
        }
        Ok(())
    }
}
impl ChildObjectResolver for TemporaryStore<'_> {
    fn read_child_object(
        &self,
        parent: &ObjectID,
        child: &ObjectID,
        child_version_upper_bound: SequenceNumber,
    ) -> SuiResult<Option<Object>> {
        let obj_opt = self.execution_results.written_objects.get(child);
        if obj_opt.is_some() {
            Ok(obj_opt.cloned())
        } else {
            self.store
                .read_child_object(parent, child, child_version_upper_bound)
        }
    }
    fn get_object_received_at_version(
        &self,
        owner: &ObjectID,
        receiving_object_id: &ObjectID,
        receive_object_at_version: SequenceNumber,
        epoch_id: EpochId,
    ) -> SuiResult<Option<Object>> {
        debug_assert!(!self
            .execution_results
            .written_objects
            .contains_key(receiving_object_id));
        debug_assert!(!self
            .execution_results
            .deleted_object_ids
            .contains(receiving_object_id));
        self.store.get_object_received_at_version(
            owner,
            receiving_object_id,
            receive_object_at_version,
            epoch_id,
        )
    }
}
impl Storage for TemporaryStore<'_> {
    fn reset(&mut self) {
        self.drop_writes();
    }
    fn read_object(&self, id: &ObjectID) -> Option<&Object> {
        TemporaryStore::read_object(self, id)
    }
    fn record_execution_results(
        &mut self,
        results: ExecutionResults,
    ) -> Result<(), ExecutionError> {
        let ExecutionResults::V2(results) = results else {
            panic!("ExecutionResults::V2 expected in sui-execution v1 and above");
        };
        self.execution_results.merge_results(results);
        Ok(())
    }
    fn save_loaded_runtime_objects(
        &mut self,
        loaded_runtime_objects: BTreeMap<ObjectID, DynamicallyLoadedObjectMetadata>,
    ) {
        TemporaryStore::save_loaded_runtime_objects(self, loaded_runtime_objects)
    }
    fn save_wrapped_object_containers(
        &mut self,
        _wrapped_object_containers: BTreeMap<ObjectID, ObjectID>,
    ) {
        unreachable!("Unused in v1")
    }
    fn check_coin_deny_list(
        &self,
        _receiving_funds_type_and_owners: BTreeMap<TypeTag, BTreeSet<SuiAddress>>,
    ) -> DenyListResult {
        unreachable!("Coin denylist v2 is not supported in sui-execution v1");
    }
    fn record_generated_object_ids(&mut self, _generated_ids: BTreeSet<ObjectID>) {
        unreachable!(
            "Generated object IDs are not recorded in ExecutionResults in sui-execution v1"
        );
    }
}
impl BackingPackageStore for TemporaryStore<'_> {
    fn get_package_object(&self, package_id: &ObjectID) -> SuiResult<Option<PackageObject>> {
        if let Some(obj) = self.read_object(package_id) {
            Ok(Some(PackageObject::new(obj.clone())))
        } else {
            self.store.get_package_object(package_id).inspect(|obj| {
                if let Some(v) = obj {
                    if !self
                        .runtime_packages_loaded_from_db
                        .read()
                        .contains_key(package_id)
                    {
                        self.runtime_packages_loaded_from_db
                            .write()
                            .insert(*package_id, v.clone());
                    }
                }
            })
        }
    }
}
impl ParentSync for TemporaryStore<'_> {
    fn get_latest_parent_entry_ref_deprecated(&self, _object_id: ObjectID) -> Option<ObjectRef> {
        unreachable!("Never called in newer protocol versions")
    }
}