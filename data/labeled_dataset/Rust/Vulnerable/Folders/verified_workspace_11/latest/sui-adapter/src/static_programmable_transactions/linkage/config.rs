use crate::{
    data_store::PackageStore,
    static_programmable_transactions::linkage::resolution::{
        ResolutionTable, VersionConstraint, add_and_unify,
    },
};
use move_binary_format::binary_config::BinaryConfig;
use sui_types::{
    MOVE_STDLIB_PACKAGE_ID, SUI_FRAMEWORK_PACKAGE_ID, SUI_SYSTEM_PACKAGE_ID, base_types::ObjectID,
    error::ExecutionError,
};
const NATIVE_PACKAGE_IDS: &[ObjectID] = &[
    SUI_FRAMEWORK_PACKAGE_ID,
    SUI_SYSTEM_PACKAGE_ID,
    MOVE_STDLIB_PACKAGE_ID,
];
#[derive(Debug)]
pub struct ResolutionConfig {
    pub linkage_config: LinkageConfig,
    pub binary_config: BinaryConfig,
}
#[derive(Debug)]
pub struct LinkageConfig {
    pub always_include_system_packages: bool,
}
impl ResolutionConfig {
    pub fn new(linkage_config: LinkageConfig, binary_config: BinaryConfig) -> Self {
        Self {
            linkage_config,
            binary_config,
        }
    }
}
impl LinkageConfig {
    pub fn legacy_linkage_settings(always_include_system_packages: bool) -> Self {
        Self {
            always_include_system_packages,
        }
    }
    pub(crate) fn resolution_table_with_native_packages(
        &self,
        store: &dyn PackageStore,
    ) -> Result<ResolutionTable, ExecutionError> {
        let mut resolution_table = ResolutionTable::empty();
        if self.always_include_system_packages {
            for id in NATIVE_PACKAGE_IDS {
                #[cfg(debug_assertions)]
                {
                    use crate::static_programmable_transactions::linkage::resolution::get_package;
                    let package = get_package(id, store)?;
                    debug_assert_eq!(package.id(), *id);
                    debug_assert_eq!(package.original_package_id(), *id);
                }
                add_and_unify(id, store, &mut resolution_table, VersionConstraint::exact)?;
            }
        }
        Ok(resolution_table)
    }
}