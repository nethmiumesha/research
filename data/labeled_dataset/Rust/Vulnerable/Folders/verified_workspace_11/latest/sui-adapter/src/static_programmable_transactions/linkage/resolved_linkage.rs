use crate::{
    data_store::PackageStore,
    static_programmable_transactions::linkage::resolution::{
        ResolutionTable, VersionConstraint, add_and_unify, get_package,
    },
};
use move_core_types::account_address::AccountAddress;
use std::{collections::BTreeMap, rc::Rc};
use sui_types::{base_types::ObjectID, error::ExecutionError};
#[derive(Clone, Debug)]
pub struct RootedLinkage {
    pub link_context: AccountAddress,
    pub resolved_linkage: Rc<ResolvedLinkage>,
}
impl RootedLinkage {
    pub fn new(link_context: AccountAddress, resolved_linkage: ResolvedLinkage) -> RootedLinkage {
        Self {
            link_context,
            resolved_linkage: Rc::new(resolved_linkage),
        }
    }
    pub fn new_for_publication(
        link_context: ObjectID,
        original_package_id: ObjectID,
        mut resolved_linkage: ResolvedLinkage,
    ) -> RootedLinkage {
        resolved_linkage
            .linkage
            .insert(original_package_id, link_context);
        resolved_linkage
            .linkage_resolution
            .insert(link_context, original_package_id);
        let resolved_linkage = Rc::new(resolved_linkage);
        Self {
            link_context: *link_context,
            resolved_linkage,
        }
    }
}
#[derive(Debug)]
pub struct ResolvedLinkage {
    pub linkage: BTreeMap<ObjectID, ObjectID>,
    pub linkage_resolution: BTreeMap<ObjectID, ObjectID>,
}
impl ResolvedLinkage {
    pub fn resolve_to_original_id(&self, object_id: &ObjectID) -> Option<ObjectID> {
        self.linkage_resolution.get(object_id).copied()
    }
    pub fn type_linkage(
        ids: &[ObjectID],
        store: &dyn PackageStore,
    ) -> Result<Self, ExecutionError> {
        let mut resolution_table = ResolutionTable::empty();
        for id in ids {
            let pkg = get_package(id, store)?;
            let transitive_deps = pkg
                .linkage_table()
                .values()
                .map(|info| info.upgraded_id)
                .collect::<Vec<_>>();
            let package_id = pkg.id();
            add_and_unify(
                &package_id,
                store,
                &mut resolution_table,
                VersionConstraint::at_least,
            )?;
            for object_id in transitive_deps.iter() {
                add_and_unify(
                    object_id,
                    store,
                    &mut resolution_table,
                    VersionConstraint::at_least,
                )?;
            }
        }
        Ok(ResolvedLinkage::from_resolution_table(resolution_table))
    }
    pub(crate) fn from_resolution_table(resolution_table: ResolutionTable) -> Self {
        let mut linkage = BTreeMap::new();
        for (original_id, resolution) in resolution_table.resolution_table {
            match resolution {
                VersionConstraint::Exact(_version, object_id)
                | VersionConstraint::AtLeast(_version, object_id) => {
                    linkage.insert(original_id, object_id);
                }
            }
        }
        Self {
            linkage,
            linkage_resolution: resolution_table.all_versions_resolution_table,
        }
    }
}