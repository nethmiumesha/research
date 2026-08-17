use crate::gas_charger::GasCharger;
use parking_lot::RwLock;
use std::collections::{BTreeMap, BTreeSet, HashSet};
use sui_protocol_config::ProtocolConfig;
use sui_types::committee::EpochId;
use sui_types::effects::{TransactionEffects, TransactionEvents};
use sui_types::execution::{DynamicallyLoadedObjectMetadata, ExecutionResults, SharedInput};
use sui_types::execution_status::ExecutionStatus;
use sui_types::inner_temporary_store::InnerTemporaryStore;
use sui_types::layout_resolver::LayoutResolver;
use sui_types::storage::{BackingStore, DeleteKindWithOldVersion, DenyListResult, PackageObject};
use sui_types::sui_system_state::{get_sui_system_state_wrapper, AdvanceEpochParams};
use sui_types::{
    base_types::{
        ObjectDigest, ObjectID, ObjectRef, SequenceNumber, SuiAddress, TransactionDigest,
        VersionDigest,
    },
    error::{ExecutionError, SuiResult},
    event::Event,
    gas::GasCostSummary,
    object::Owner,
    object::{Data, Object},
    storage::{
        BackingPackageStore, ChildObjectResolver, ObjectChange, ParentSync, Storage, WriteKind,
    },
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
    written: BTreeMap<ObjectID, (Object, WriteKind)>,
    deleted: BTreeMap<ObjectID, DeleteKindWithOldVersion>,
    loaded_child_objects: BTreeMap<ObjectID, DynamicallyLoadedObjectMetadata>,
    events: Vec<Event>,
    protocol_config: ProtocolConfig,
    runtime_packages_loaded_from_db: RwLock<BTreeMap<ObjectID, PackageObject>>,
}
impl<'backing> TemporaryStore<'backing> {
    pub fn new(
        store: &'backing dyn BackingStore,
        input_objects: InputObjects,
        tx_digest: TransactionDigest,
        protocol_config: &ProtocolConfig,
    ) -> Self {
        let mutable_input_refs = input_objects.exclusive_mutable_inputs();
        let lamport_timestamp = input_objects.lamport_timestamp(&[]);
        let deleted_consensus_objects = input_objects.consensus_stream_ended_objects();
        let objects = input_objects.into_object_map();
        Self {
            store,
            tx_digest,
            input_objects: objects,
            deleted_consensus_objects,
            lamport_timestamp,
            mutable_input_refs,
            written: BTreeMap::new(),
            deleted: BTreeMap::new(),
            events: Vec::new(),
            protocol_config: protocol_config.clone(),
            loaded_child_objects: BTreeMap::new(),
            runtime_packages_loaded_from_db: RwLock::new(BTreeMap::new()),
        }
    }
    pub fn objects(&self) -> &BTreeMap<ObjectID, Object> {
        &self.input_objects
    }
    pub fn update_object_version_and_prev_tx(&mut self) {
        #[cfg(debug_assertions)]
        {
            self.check_invariants();
        }
        for (id, (obj, kind)) in self.written.iter_mut() {
            match &mut obj.data {
                Data::Move(obj) => {
                    obj.increment_version_to(self.lamport_timestamp);
                }
                Data::Package(pkg) => {
                    if *kind == WriteKind::Mutate {
                        pkg.increment_version();
                    }
                }
            }
            if let Owner::Shared {
                initial_shared_version,
            } = &mut obj.owner
            {
                if *kind == WriteKind::Create {
                    assert_eq!(
                        *initial_shared_version,
                        SequenceNumber::new(),
                        "Initial version should be blank before this point for {id:?}",
                    );
                    *initial_shared_version = self.lamport_timestamp;
                }
            }
        }
    }
    pub fn into_inner(self) -> InnerTemporaryStore {
        InnerTemporaryStore {
            input_objects: self.input_objects,
            stream_ended_consensus_objects: self.deleted_consensus_objects,
            mutable_inputs: self.mutable_input_refs,
            written: self
                .written
                .into_iter()
                .map(|(id, (obj, _))| (id, obj))
                .collect(),
            events: TransactionEvents { data: self.events },
            accumulator_events: vec![],
            loaded_runtime_objects: self.loaded_child_objects,
            runtime_packages_loaded_from_db: self.runtime_packages_loaded_from_db.into_inner(),
            lamport_version: self.lamport_timestamp,
            binary_config: self.protocol_config.binary_config(None),
            accumulator_running_max_withdraws: BTreeMap::new(),
        }
    }
    fn ensure_active_inputs_mutated(&mut self) {
        let mut to_be_updated = vec![];
        for id in self.mutable_input_refs.keys() {
            if !self.written.contains_key(id) && !self.deleted.contains_key(id) {
                to_be_updated.push(self.input_objects[id].clone());
            }
        }
        for object in to_be_updated {
            self.write_object(object.clone(), WriteKind::Mutate);
        }
    }
    pub fn to_effects(
        mut self,
        shared_object_refs: Vec<SharedInput>,
        transaction_digest: &TransactionDigest,
        transaction_dependencies: Vec<TransactionDigest>,
        gas_cost_summary: GasCostSummary,
        status: ExecutionStatus,
        gas_charger: &mut GasCharger,
        epoch: EpochId,
    ) -> (InnerTemporaryStore, TransactionEffects) {
        let mut modified_at_versions = vec![];
        self.written.iter_mut().for_each(|(id, (obj, kind))| {
            if *kind == WriteKind::Mutate {
                modified_at_versions.push((*id, obj.version()))
            }
        });
        self.deleted.iter_mut().for_each(|(id, kind)| {
            if let Some(version) = kind.old_version() {
                modified_at_versions.push((*id, version));
            }
        });
        self.update_object_version_and_prev_tx();
        let mut deleted = vec![];
        let mut wrapped = vec![];
        let mut unwrapped_then_deleted = vec![];
        for (id, kind) in &self.deleted {
            match kind {
                DeleteKindWithOldVersion::Normal(_) => deleted.push((
                    *id,
                    self.lamport_timestamp,
                    ObjectDigest::OBJECT_DIGEST_DELETED,
                )),
                DeleteKindWithOldVersion::UnwrapThenDelete
                | DeleteKindWithOldVersion::UnwrapThenDeleteDEPRECATED(_) => unwrapped_then_deleted
                    .push((
                        *id,
                        self.lamport_timestamp,
                        ObjectDigest::OBJECT_DIGEST_DELETED,
                    )),
                DeleteKindWithOldVersion::Wrap(_) => wrapped.push((
                    *id,
                    self.lamport_timestamp,
                    ObjectDigest::OBJECT_DIGEST_WRAPPED,
                )),
            }
        }
        let updated_gas_object_info = if let Some(coin_id) = gas_charger.gas_coin() {
            let (object, _kind) = &self.written[&coin_id];
            (object.compute_object_reference(), object.owner.clone())
        } else {
            (
                (ObjectID::ZERO, SequenceNumber::default(), ObjectDigest::MIN),
                Owner::AddressOwner(SuiAddress::default()),
            )
        };
        let mut mutated = vec![];
        let mut created = vec![];
        let mut unwrapped = vec![];
        for (object, kind) in self.written.values() {
            let object_ref = object.compute_object_reference();
            let owner = object.owner.clone();
            match kind {
                WriteKind::Mutate => mutated.push((object_ref, owner)),
                WriteKind::Create => created.push((object_ref, owner)),
                WriteKind::Unwrap => unwrapped.push((object_ref, owner)),
            }
        }
        let inner = self.into_inner();
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
            transaction_dependencies,
        );
        (inner, effects)
    }
    #[cfg(debug_assertions)]
    fn check_invariants(&self) {
        debug_assert!(
            {
                let mut used = HashSet::new();
                self.written.iter().all(|(elt, _)| used.insert(elt));
                self.deleted.iter().all(move |elt| used.insert(elt.0))
            },
            "Object both written and deleted."
        );
        debug_assert!(
            {
                let mut used = HashSet::new();
                self.written.iter().all(|(elt, _)| used.insert(elt));
                self.deleted.iter().all(|elt| used.insert(elt.0));
                self.mutable_input_refs.keys().all(|elt| !used.insert(elt))
            },
            "Mutable input neither written nor deleted."
        );
        debug_assert!(
            {
                self.written
                    .iter()
                    .all(|(_, (obj, _))| obj.previous_transaction == self.tx_digest)
            },
            "Object previous transaction not properly set",
        );
        if self.protocol_config.simplified_unwrap_then_delete() {
            debug_assert!(self.deleted.iter().all(|(_, kind)| {
                !matches!(
                    kind,
                    DeleteKindWithOldVersion::UnwrapThenDeleteDEPRECATED(_)
                )
            }));
        } else {
            debug_assert!(self
                .deleted
                .iter()
                .all(|(_, kind)| { !matches!(kind, DeleteKindWithOldVersion::UnwrapThenDelete) }));
        }
    }
    pub fn write_object(&mut self, mut object: Object, kind: WriteKind) {
        debug_assert!(!self.deleted.contains_key(&object.id()));
        debug_assert!(
            kind != WriteKind::Create
                || object.is_immutable()
                || object.version() == SequenceNumber::MIN,
            "Created mutable objects should not have a version set",
        );
        object.previous_transaction = self.tx_digest;
        self.written.insert(object.id(), (object, kind));
    }
    pub fn delete_object(&mut self, id: &ObjectID, kind: DeleteKindWithOldVersion) {
        debug_assert!(!self.written.contains_key(id));
        #[cfg(debug_assertions)]
        if let Some(object) = self.read_object(id) {
            if object.is_immutable() {
                let digest = self.tx_digest;
                panic!("Internal invariant violation in tx {digest}: Deleting immutable object {id}, delete kind {kind:?}")
            }
        }
        self.deleted.insert(*id, kind);
    }
    pub fn drop_writes(&mut self) {
        self.written.clear();
        self.deleted.clear();
        self.events.clear();
    }
    pub fn log_event(&mut self, event: Event) {
        self.events.push(event)
    }
    pub fn read_object(&self, id: &ObjectID) -> Option<&Object> {
        debug_assert!(!self.deleted.contains_key(id));
        self.written
            .get(id)
            .map(|(obj, _kind)| obj)
            .or_else(|| self.input_objects.get(id))
    }
    pub fn apply_object_changes(&mut self, changes: BTreeMap<ObjectID, ObjectChange>) {
        for (id, change) in changes {
            match change {
                ObjectChange::Write(new_value, kind) => self.write_object(new_value, kind),
                ObjectChange::Delete(kind) => self.delete_object(&id, kind),
            }
        }
    }
    pub fn save_loaded_runtime_objects(
        &mut self,
        loaded_runtime_objects: BTreeMap<ObjectID, DynamicallyLoadedObjectMetadata>,
    ) {
        #[cfg(debug_assertions)]
        {
            for (id, v1) in &loaded_runtime_objects {
                if let Some(v2) = self.loaded_child_objects.get(id) {
                    assert_eq!(v1, v2);
                }
            }
            for (id, v1) in &self.loaded_child_objects {
                if let Some(v2) = loaded_runtime_objects.get(id) {
                    assert_eq!(v1, v2);
                }
            }
        }
        self.loaded_child_objects.extend(loaded_runtime_objects);
    }
    pub fn estimate_effects_size_upperbound(&self) -> usize {
        TransactionEffects::estimate_effects_size_upperbound_v1(
            self.written.len(),
            self.mutable_input_refs.len(),
            self.deleted.len(),
            self.input_objects.len(),
        )
    }
    pub fn written_objects_size(&self) -> usize {
        self.written
            .iter()
            .fold(0, |sum, obj| sum + obj.1 .0.object_size_for_gas_metering())
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
        self.write_object(system_state_wrapper, WriteKind::Mutate);
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
        for (id, (_new_obj, kind)) in &self.written {
            if authenticated_objs.contains(id) || gas_objs.contains(id) {
                continue;
            }
            match kind {
                WriteKind::Mutate => {
                    let old_obj = self.store.get_object(id).unwrap_or_else(|| {
                        panic!("Mutated object must exist in the store: ID = {:?}", id)
                    });
                    match &old_obj.owner {
                        Owner::ObjectOwner(_parent) => {
                            objs_to_authenticate.push(*id);
                        }
                        Owner::AddressOwner(_) | Owner::Shared { .. } => {
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
                WriteKind::Create | WriteKind::Unwrap => {
                }
            }
        }
        for (id, kind) in &self.deleted {
            if authenticated_objs.contains(id) || gas_objs.contains(id) {
                continue;
            }
            match kind {
                DeleteKindWithOldVersion::Normal(_) | DeleteKindWithOldVersion::Wrap(_) => {
                    let old_obj = self.store.get_object(id).unwrap();
                    match &old_obj.owner {
                        Owner::ObjectOwner(_) => {
                            objs_to_authenticate.push(*id);
                        }
                        Owner::AddressOwner(_) | Owner::Shared { .. } => {
                            unreachable!("Should already be in authenticated_objs")
                        }
                        Owner::Immutable => unreachable!("Immutable objects cannot be deleted"),
                        Owner::ConsensusAddressOwner { .. } => {
                            unimplemented!(
                                "ConsensusAddressOwner does not exist for this execution version"
                            )
                        }
                    }
                }
                DeleteKindWithOldVersion::UnwrapThenDelete
                | DeleteKindWithOldVersion::UnwrapThenDeleteDEPRECATED(_) => {
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
                Owner::ObjectOwner(parent) => ObjectID::from(*parent),
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
    fn get_input_storage_rebate(&self, id: &ObjectID, expected_version: SequenceNumber) -> u64 {
        if let Some(old_obj) = self.input_objects.get(id) {
            old_obj.storage_rebate
        } else if let Some(metadata) = self.loaded_child_objects.get(id) {
            debug_assert_eq!(metadata.version, expected_version);
            metadata.storage_rebate
        } else if let Some(obj) = self.store.get_object_by_key(id, expected_version) {
            debug_assert!(obj.is_package());
            obj.storage_rebate
        } else {
            panic!(
                "Looking up storage rebate of mutated object {:?} should not fail",
                id
            )
        }
    }
    pub(crate) fn ensure_gas_and_input_mutated(&mut self, gas_charger: &mut GasCharger) {
        if let Some(gas_object_id) = gas_charger.gas_coin() {
            let gas_object = self
                .read_object(&gas_object_id)
                .expect("We constructed the object map so it should always have the gas object id")
                .clone();
            self.written
                .entry(gas_object_id)
                .or_insert_with(|| (gas_object, WriteKind::Mutate));
        }
        self.ensure_active_inputs_mutated();
    }
    pub(crate) fn collect_storage_and_rebate(&mut self, gas_charger: &mut GasCharger) {
        let mut objects_to_update = vec![];
        for (object_id, (object, write_kind)) in &mut self.written {
            let old_storage_rebate = match write_kind {
                WriteKind::Create | WriteKind::Unwrap => 0,
                WriteKind::Mutate => {
                    if let Some(old_obj) = self.input_objects.get(object_id) {
                        old_obj.storage_rebate
                    } else {
                        let expected_version = object.version();
                        if let Some(old_obj) =
                            self.store.get_object_by_key(object_id, expected_version)
                        {
                            old_obj.storage_rebate
                        } else {
                            panic!("Looking up storage rebate of mutated object should not fail");
                        }
                    }
                }
            };
            let new_object_size = object.object_size_for_gas_metering();
            let new_storage_rebate =
                gas_charger.track_storage_mutation(*object_id, new_object_size, old_storage_rebate);
            object.storage_rebate = new_storage_rebate;
            if !object.is_immutable() {
                objects_to_update.push((object.clone(), *write_kind));
            }
        }
        self.collect_rebate(gas_charger);
        for (object, write_kind) in objects_to_update {
            self.write_object(object, write_kind);
        }
    }
    pub(crate) fn collect_rebate(&self, gas_charger: &mut GasCharger) {
        for (object_id, kind) in &self.deleted {
            match kind {
                DeleteKindWithOldVersion::Wrap(version)
                | DeleteKindWithOldVersion::Normal(version) => {
                    let storage_rebate = self.get_input_storage_rebate(object_id, *version);
                    gas_charger.track_storage_mutation(*object_id, 0, storage_rebate);
                }
                DeleteKindWithOldVersion::UnwrapThenDelete
                | DeleteKindWithOldVersion::UnwrapThenDeleteDEPRECATED(_) => {
                }
            }
        }
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
        let (new_object, _) =
            wrapper.advance_epoch_safe_mode(params, self.store.as_object_store(), protocol_config);
        self.write_object(new_object, WriteKind::Mutate);
    }
}
type ModifiedObjectInfo<'a> = (ObjectID, Option<(SequenceNumber, u64)>, Option<&'a Object>);
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
        self.written
            .iter()
            .map(|(id, (object, kind))| match kind {
                WriteKind::Mutate => {
                    let version = object.version();
                    let storage_rebate = self.get_input_storage_rebate(id, version);
                    (*id, Some((object.version(), storage_rebate)), Some(object))
                }
                WriteKind::Create | WriteKind::Unwrap => (*id, None, Some(object)),
            })
            .chain(self.deleted.iter().filter_map(|(id, kind)| match kind {
                DeleteKindWithOldVersion::Normal(version)
                | DeleteKindWithOldVersion::Wrap(version) => {
                    let storage_rebate = self.get_input_storage_rebate(id, *version);
                    Some((*id, Some((*version, storage_rebate)), None))
                }
                DeleteKindWithOldVersion::UnwrapThenDelete
                | DeleteKindWithOldVersion::UnwrapThenDeleteDEPRECATED(_) => None,
            }))
            .collect()
    }
    pub fn check_sui_conserved(
        &self,
        gas_summary: &GasCostSummary,
        advance_epoch_gas_summary: Option<(u64, u64)>,
        layout_resolver: &mut impl LayoutResolver,
        do_expensive_checks: bool,
    ) -> Result<(), ExecutionError> {
        let mut total_input_sui = 0;
        let mut total_output_sui = 0;
        let mut total_input_rebate = 0;
        let mut total_output_rebate = 0;
        for (id, input, output) in self.get_modified_objects() {
            if let Some((version, storage_rebate)) = input {
                total_input_rebate += storage_rebate;
                if do_expensive_checks {
                    total_input_sui += self.get_input_sui(&id, version, layout_resolver)?;
                }
            }
            if let Some(object) = output {
                total_output_rebate += object.storage_rebate;
                if do_expensive_checks {
                    total_output_sui += object.get_total_sui(layout_resolver).map_err(|e| {
                        make_invariant_violation!(
                            "Failed looking up output SUI in SUI conservation checking for \
                             mutated type {:?}: {e:#?}",
                            object.struct_tag(),
                        )
                    })?;
                }
            }
        }
        if do_expensive_checks {
            total_output_sui +=
                gas_summary.computation_cost + gas_summary.non_refundable_storage_fee;
            if let Some((epoch_fees, epoch_rebates)) = advance_epoch_gas_summary {
                total_input_sui += epoch_fees;
                total_output_sui += epoch_rebates;
            }
            if total_input_sui != total_output_sui {
                return Err(ExecutionError::invariant_violation(
                format!("SUI conservation failed: input={}, output={}, this transaction either mints or burns SUI",
                total_input_sui,
                total_output_sui))
            );
            }
        }
        if total_input_rebate != gas_summary.storage_rebate + gas_summary.non_refundable_storage_fee
        {
        }
        if gas_summary.storage_cost != total_output_rebate {
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
        debug_assert!(!self.deleted.contains_key(child));
        let obj_opt = self.written.get(child).map(|(obj, _kind)| obj);
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
        debug_assert!(!self.deleted.contains_key(receiving_object_id));
        debug_assert!(!self.written.contains_key(receiving_object_id));
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
        TemporaryStore::drop_writes(self);
    }
    fn read_object(&self, id: &ObjectID) -> Option<&Object> {
        TemporaryStore::read_object(self, id)
    }
    fn record_execution_results(
        &mut self,
        results: ExecutionResults,
    ) -> Result<(), ExecutionError> {
        let ExecutionResults::V1(results) = results else {
            panic!("ExecutionResults::V1 expected in sui-execution v0");
        };
        TemporaryStore::apply_object_changes(self, results.object_changes);
        for event in results.user_events {
            TemporaryStore::log_event(self, event);
        }
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
        unreachable!("Unused in v0")
    }
    fn check_coin_deny_list(
        &self,
        _receiving_funds_type_and_owners: BTreeMap<TypeTag, BTreeSet<SuiAddress>>,
    ) -> DenyListResult {
        unreachable!("Coin denylist v2 is not supported in sui-execution v0");
    }
    fn record_generated_object_ids(&mut self, _generated_ids: BTreeSet<ObjectID>) {
        unreachable!(
            "Generated object IDs are not recorded in ExecutionResults in sui-execution v0"
        );
    }
}
impl BackingPackageStore for TemporaryStore<'_> {
    fn get_package_object(&self, package_id: &ObjectID) -> SuiResult<Option<PackageObject>> {
        if let Some((obj, _)) = self.written.get(package_id) {
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
    fn get_latest_parent_entry_ref_deprecated(&self, object_id: ObjectID) -> Option<ObjectRef> {
        self.store.get_latest_parent_entry_ref_deprecated(object_id)
    }
}