use crate::data_store::PackageStore;
use std::{
    collections::{BTreeMap, btree_map::Entry},
    rc::Rc,
};
use sui_types::{
    base_types::{ObjectID, SequenceNumber},
    error::ExecutionError,
    execution_status::ExecutionErrorKind,
    move_package::MovePackage,
};
#[derive(Debug, Clone)]
pub enum VersionConstraint {
    Exact(SequenceNumber, ObjectID),
    AtLeast(SequenceNumber, ObjectID),
}
#[derive(Debug, Clone)]
pub(crate) struct ResolutionTable {
    pub(crate) resolution_table: BTreeMap<ObjectID, VersionConstraint>,
    pub(crate) all_versions_resolution_table: BTreeMap<ObjectID, ObjectID>,
}
impl ResolutionTable {
    pub fn empty() -> Self {
        Self {
            resolution_table: BTreeMap::new(),
            all_versions_resolution_table: BTreeMap::new(),
        }
    }
}
impl VersionConstraint {
    pub fn exact(pkg: &MovePackage) -> Option<VersionConstraint> {
        Some(VersionConstraint::Exact(pkg.version(), pkg.id()))
    }
    pub fn at_least(pkg: &MovePackage) -> Option<VersionConstraint> {
        Some(VersionConstraint::AtLeast(pkg.version(), pkg.id()))
    }
    pub fn unify(&self, other: &VersionConstraint) -> Result<VersionConstraint, ExecutionError> {
        match (&self, other) {
            (VersionConstraint::Exact(sv, self_id), VersionConstraint::Exact(ov, other_id)) => {
                if self_id != other_id || sv != ov {
                    Err(ExecutionError::new_with_source(
                        ExecutionErrorKind::InvalidLinkage,
                        format!(
                            "exact/exact conflicting resolutions for package: linkage requires the same package \
                                 at different versions. Linkage requires exactly {self_id} (version {sv}) and \
                                 {other_id} (version {ov}) to be used in the same transaction"
                        ),
                    ))
                } else {
                    Ok(VersionConstraint::Exact(*sv, *self_id))
                }
            }
            (
                VersionConstraint::AtLeast(self_version, sid),
                VersionConstraint::AtLeast(other_version, oid),
            ) => {
                let id = if self_version > other_version {
                    *sid
                } else {
                    *oid
                };
                Ok(VersionConstraint::AtLeast(
                    *self_version.max(other_version),
                    id,
                ))
            }
            (
                VersionConstraint::Exact(exact_version, exact_id),
                VersionConstraint::AtLeast(at_least_version, at_least_id),
            )
            | (
                VersionConstraint::AtLeast(at_least_version, at_least_id),
                VersionConstraint::Exact(exact_version, exact_id),
            ) => {
                if exact_version < at_least_version {
                    return Err(ExecutionError::new_with_source(
                        ExecutionErrorKind::InvalidLinkage,
                        format!(
                            "Exact/AtLeast conflicting resolutions for package: linkage requires exactly this \
                                 package {exact_id} (version {exact_version}) and also at least the following \
                                 version of the package {at_least_id} at version {at_least_version}. However \
                                 {exact_id} is at version {exact_version} which is less than {at_least_version}."
                        ),
                    ));
                }
                Ok(VersionConstraint::Exact(*exact_version, *exact_id))
            }
        }
    }
}
pub(crate) fn get_package(
    object_id: &ObjectID,
    store: &dyn PackageStore,
) -> Result<Rc<MovePackage>, ExecutionError> {
    store
        .get_package(object_id)
        .map_err(|e| {
            ExecutionError::new_with_source(ExecutionErrorKind::PublishUpgradeMissingDependency, e)
        })?
        .ok_or_else(|| ExecutionError::from_kind(ExecutionErrorKind::InvalidLinkage))
}
pub(crate) fn add_and_unify(
    object_id: &ObjectID,
    store: &dyn PackageStore,
    resolution_table: &mut ResolutionTable,
    resolution_fn: fn(&MovePackage) -> Option<VersionConstraint>,
) -> Result<(), ExecutionError> {
    let package = get_package(object_id, store)?;
    let Some(resolution) = resolution_fn(&package) else {
        return Ok(());
    };
    let original_pkg_id = package.original_package_id();
    if let Entry::Vacant(e) = resolution_table.resolution_table.entry(original_pkg_id) {
        e.insert(resolution);
    } else {
        let existing_unifier = resolution_table
            .resolution_table
            .get_mut(&original_pkg_id)
            .expect("Guaranteed to exist");
        *existing_unifier = existing_unifier.unify(&resolution)?;
    }
    if !resolution_table
        .all_versions_resolution_table
        .contains_key(object_id)
    {
        resolution_table
            .all_versions_resolution_table
            .insert(*object_id, original_pkg_id);
    }
    Ok(())
}