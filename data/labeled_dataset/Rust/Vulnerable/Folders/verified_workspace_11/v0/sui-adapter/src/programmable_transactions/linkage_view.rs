use std::{
    cell::RefCell,
    collections::{hash_map::Entry, BTreeMap, HashMap, HashSet},
    str::FromStr,
};
use crate::execution_value::SuiResolver;
use move_core_types::{
    account_address::AccountAddress,
    identifier::{IdentStr, Identifier},
    language_storage::ModuleId,
    resolver::{LinkageResolver, ModuleResolver},
};
use sui_types::storage::{get_module, PackageObject};
use sui_types::{
    base_types::ObjectID,
    error::{ExecutionError, SuiError, SuiResult},
    move_package::{MovePackage, TypeOrigin, UpgradeInfo},
    storage::BackingPackageStore,
};
pub struct LinkageView<'state> {
    resolver: Box<dyn SuiResolver + 'state>,
    linkage_info: LinkageInfo,
    type_origin_cache: RefCell<HashMap<ModuleId, HashMap<Identifier, AccountAddress>>>,
    past_contexts: RefCell<HashSet<ObjectID>>,
}
#[derive(Debug)]
pub enum LinkageInfo {
    Unset,
    Universal,
    Set(PackageLinkage),
}
#[derive(Debug)]
pub struct PackageLinkage {
    storage_id: AccountAddress,
    runtime_id: AccountAddress,
    link_table: BTreeMap<ObjectID, UpgradeInfo>,
}
pub struct SavedLinkage(PackageLinkage);
impl<'state> LinkageView<'state> {
    pub fn new(resolver: Box<dyn SuiResolver + 'state>, linkage_info: LinkageInfo) -> Self {
        Self {
            resolver,
            linkage_info,
            type_origin_cache: RefCell::new(HashMap::new()),
            past_contexts: RefCell::new(HashSet::new()),
        }
    }
    pub fn reset_linkage(&mut self) {
        if let LinkageInfo::Set(_) = &self.linkage_info {
            self.linkage_info = LinkageInfo::Unset;
        }
    }
    pub fn has_linkage(&self, context: ObjectID) -> bool {
        match &self.linkage_info {
            LinkageInfo::Unset => false,
            LinkageInfo::Universal => true,
            LinkageInfo::Set(linkage) => linkage.storage_id == *context,
        }
    }
    pub fn steal_linkage(&mut self) -> Option<SavedLinkage> {
        if let LinkageInfo::Universal = &self.linkage_info {
            None
        } else {
            match std::mem::replace(&mut self.linkage_info, LinkageInfo::Unset) {
                LinkageInfo::Set(linkage) => Some(SavedLinkage(linkage)),
                LinkageInfo::Unset => None,
                LinkageInfo::Universal => unreachable!(),
            }
        }
    }
    pub fn restore_linkage(&mut self, saved: Option<SavedLinkage>) -> Result<(), ExecutionError> {
        let Some(SavedLinkage(saved)) = saved else {
            return Ok(());
        };
        match &self.linkage_info {
            LinkageInfo::Unset => (),
            LinkageInfo::Universal => (),
            LinkageInfo::Set(existing) => {
                invariant_violation!(
                    "Attempt to overwrite linkage by restoring: {saved:#?} \
                     Existing linkage: {existing:#?}",
                )
            }
        }
        self.linkage_info = LinkageInfo::Set(saved);
        Ok(())
    }
    pub fn set_linkage(&mut self, context: &MovePackage) -> Result<AccountAddress, ExecutionError> {
        match &self.linkage_info {
            LinkageInfo::Unset => (),
            LinkageInfo::Universal => return Ok(*context.id()),
            LinkageInfo::Set(existing) => {
                invariant_violation!(
                    "Attempt to overwrite linkage info with context from {}. \
                     Existing linkage: {existing:#?}",
                    context.id(),
                )
            }
        }
        let linkage = PackageLinkage::from(context);
        let storage_id = context.id();
        let runtime_id = linkage.runtime_id;
        self.linkage_info = LinkageInfo::Set(linkage);
        if !self.past_contexts.borrow_mut().insert(storage_id) {
            return Ok(runtime_id);
        }
        for TypeOrigin {
            module_name,
            datatype_name: struct_name,
            package: defining_id,
        } in context.type_origin_table()
        {
            let Ok(module_name) = Identifier::from_str(module_name) else {
                invariant_violation!("Module name isn't an identifier: {module_name}");
            };
            let Ok(struct_name) = Identifier::from_str(struct_name) else {
                invariant_violation!("Struct name isn't an identifier: {struct_name}");
            };
            let runtime_id = ModuleId::new(runtime_id, module_name);
            self.add_type_origin(runtime_id, struct_name, *defining_id)?;
        }
        Ok(runtime_id)
    }
    pub fn original_package_id(&self) -> Option<AccountAddress> {
        if let LinkageInfo::Set(linkage) = &self.linkage_info {
            Some(linkage.runtime_id)
        } else {
            None
        }
    }
    fn get_cached_type_origin(
        &self,
        runtime_id: &ModuleId,
        struct_: &IdentStr,
    ) -> Option<AccountAddress> {
        self.type_origin_cache
            .borrow()
            .get(runtime_id)?
            .get(struct_)
            .cloned()
    }
    fn add_type_origin(
        &self,
        runtime_id: ModuleId,
        struct_: Identifier,
        defining_id: ObjectID,
    ) -> Result<(), ExecutionError> {
        let mut cache = self.type_origin_cache.borrow_mut();
        let module_cache = cache.entry(runtime_id.clone()).or_default();
        match module_cache.entry(struct_) {
            Entry::Vacant(entry) => {
                entry.insert(*defining_id);
            }
            Entry::Occupied(entry) => {
                if entry.get() != &*defining_id {
                    invariant_violation!(
                        "Conflicting defining ID for {}::{}: {} and {}",
                        runtime_id,
                        entry.key(),
                        defining_id,
                        entry.get(),
                    );
                }
            }
        }
        Ok(())
    }
}
impl From<&MovePackage> for PackageLinkage {
    fn from(package: &MovePackage) -> Self {
        Self {
            storage_id: package.id().into(),
            runtime_id: package.original_package_id().into(),
            link_table: package.linkage_table().clone(),
        }
    }
}
impl LinkageResolver for LinkageView<'_> {
    type Error = SuiError;
    fn link_context(&self) -> AccountAddress {
        if let LinkageInfo::Set(linkage) = &self.linkage_info {
            linkage.storage_id
        } else {
            AccountAddress::ZERO
        }
    }
    fn relocate(&self, module_id: &ModuleId) -> Result<ModuleId, Self::Error> {
        let linkage = match &self.linkage_info {
            LinkageInfo::Set(linkage) => linkage,
            LinkageInfo::Universal => return Ok(module_id.clone()),
            LinkageInfo::Unset => {
                invariant_violation!("No linkage context set while relocating {module_id}.")
            }
        };
        if module_id.address() == &linkage.runtime_id {
            return Ok(ModuleId::new(
                linkage.storage_id,
                module_id.name().to_owned(),
            ));
        }
        let runtime_id = ObjectID::from_address(*module_id.address());
        let Some(upgrade) = linkage.link_table.get(&runtime_id) else {
            invariant_violation!(
                "Missing linkage for {runtime_id} in context {}, runtime_id is {}",
                linkage.storage_id,
                linkage.runtime_id
            );
        };
        Ok(ModuleId::new(
            upgrade.upgraded_id.into(),
            module_id.name().to_owned(),
        ))
    }
    fn defining_module(
        &self,
        runtime_id: &ModuleId,
        struct_: &IdentStr,
    ) -> Result<ModuleId, Self::Error> {
        match &self.linkage_info {
            LinkageInfo::Set(_) => (),
            LinkageInfo::Universal => return Ok(runtime_id.clone()),
            LinkageInfo::Unset => {
                invariant_violation!(
                    "No linkage context set for defining module query on {runtime_id}::{struct_}."
                )
            }
        };
        if let Some(cached) = self.get_cached_type_origin(runtime_id, struct_) {
            return Ok(ModuleId::new(cached, runtime_id.name().to_owned()));
        }
        let storage_id = ObjectID::from(*self.relocate(runtime_id)?.address());
        let Some(package) = self.resolver.get_package_object(&storage_id)? else {
            invariant_violation!("Missing dependent package in store: {storage_id}",)
        };
        for TypeOrigin {
            module_name,
            datatype_name: struct_name,
            package,
        } in package.move_package().type_origin_table()
        {
            if module_name == runtime_id.name().as_str() && struct_name == struct_.as_str() {
                self.add_type_origin(runtime_id.clone(), struct_.to_owned(), *package)?;
                return Ok(ModuleId::new(**package, runtime_id.name().to_owned()));
            }
        }
        invariant_violation!(
            "{runtime_id}::{struct_} not found in type origin table in {storage_id} (v{})",
            package.move_package().version(),
        )
    }
}
impl ModuleResolver for LinkageView<'_> {
    type Error = SuiError;
    fn get_module(&self, id: &ModuleId) -> Result<Option<Vec<u8>>, Self::Error> {
        get_module(self, id)
    }
}
impl BackingPackageStore for LinkageView<'_> {
    fn get_package_object(&self, package_id: &ObjectID) -> SuiResult<Option<PackageObject>> {
        self.resolver.get_package_object(package_id)
    }
}