pub mod cached_package_store;
pub mod legacy;
pub mod linked_data_store;
use move_core_types::identifier::IdentStr;
use std::rc::Rc;
use sui_types::{base_types::ObjectID, error::SuiResult, move_package::MovePackage};
pub trait PackageStore {
    fn get_package(&self, id: &ObjectID) -> SuiResult<Option<Rc<MovePackage>>>;
    fn resolve_type_to_defining_id(
        &self,
        module_address: ObjectID,
        module_name: &IdentStr,
        type_name: &IdentStr,
    ) -> SuiResult<Option<ObjectID>>;
}