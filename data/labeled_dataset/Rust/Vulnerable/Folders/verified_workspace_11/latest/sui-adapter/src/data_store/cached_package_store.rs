use crate::data_store::PackageStore;
use indexmap::IndexMap;
use move_core_types::identifier::IdentStr;
use std::{
    cell::RefCell,
    collections::{BTreeMap, BTreeSet},
    rc::Rc,
};
use sui_types::{
    base_types::ObjectID,
    error::{ExecutionError, SuiResult},
    move_package::MovePackage,
    storage::BackingPackageStore,
};
pub struct CachedPackageStore<'state> {
    pub package_store: Box<dyn BackingPackageStore + 'state>,
    package_cache: RefCell<BTreeMap<ObjectID, Option<Rc<MovePackage>>>>,
    type_origin_cache: RefCell<CachedTypeOriginMap>,
    new_packages: RefCell<IndexMap<ObjectID, Rc<MovePackage>>>,
    max_package_cache_size: usize,
    max_type_cache_size: usize,
}
type TypeOriginMap = BTreeMap<ObjectID, BTreeMap<(String, String), ObjectID>>;
#[derive(Debug)]
struct CachedTypeOriginMap {
    pub cached_type_origins: BTreeSet<ObjectID>,
    pub type_origin_map: TypeOriginMap,
}
impl CachedTypeOriginMap {
    pub fn new() -> Self {
        Self {
            cached_type_origins: BTreeSet::new(),
            type_origin_map: TypeOriginMap::new(),
        }
    }
}
impl<'state> CachedPackageStore<'state> {
    pub const DEFAULT_MAX_PACKAGE_CACHE_SIZE: usize = 200;
    pub const DEFAULT_MAX_TYPE_ORIGIN_CACHE_SIZE: usize = 1000;
    pub fn new(package_store: Box<dyn BackingPackageStore + 'state>) -> Self {
        Self {
            package_store,
            package_cache: RefCell::new(BTreeMap::new()),
            type_origin_cache: RefCell::new(CachedTypeOriginMap::new()),
            new_packages: RefCell::new(IndexMap::new()),
            max_package_cache_size: Self::DEFAULT_MAX_PACKAGE_CACHE_SIZE,
            max_type_cache_size: Self::DEFAULT_MAX_TYPE_ORIGIN_CACHE_SIZE,
        }
    }
    pub fn push_package(
        &self,
        id: ObjectID,
        package: Rc<MovePackage>,
    ) -> Result<(), ExecutionError> {
        debug_assert!(self.fetch_package(&id).unwrap().is_none());
        if self.new_packages.borrow_mut().insert(id, package).is_some() {
            invariant_violation!(
                "Package with ID {} already exists in the new packages. This should never happen.",
                id
            );
        }
        Ok(())
    }
    pub fn pop_package(&self, id: ObjectID) -> Result<Rc<MovePackage>, ExecutionError> {
        if self
            .new_packages
            .borrow()
            .last()
            .is_none_or(|(pkg_id, _)| *pkg_id != id)
        {
            make_invariant_violation!(
                "Tried to pop package {} from new packages, but new packages was empty or \
                it is not the most recent package inserted. This should never happen.",
                id
            );
        }
        let Some((pkg_id, pkg)) = self.new_packages.borrow_mut().pop() else {
            unreachable!(
                "We just checked that new packages is not empty, so this should never happen."
            );
        };
        assert_eq!(
            pkg_id, id,
            "Popped package ID {} does not match requested ID {}. This should never happen as was checked above.",
            pkg_id, id
        );
        Ok(pkg)
    }
    pub fn to_new_packages(&self) -> Vec<MovePackage> {
        self.new_packages
            .borrow()
            .iter()
            .map(|(_, pkg)| pkg.as_ref().clone())
            .collect()
    }
    pub fn get_package(&self, object_id: &ObjectID) -> SuiResult<Option<Rc<MovePackage>>> {
        let Some(pkg) = self.fetch_package(object_id)? else {
            return Ok(None);
        };
        let package_id = pkg.id();
        if self.type_origin_cache.borrow().cached_type_origins.len() >= self.max_type_cache_size {
            *self.type_origin_cache.borrow_mut() = CachedTypeOriginMap::new();
        }
        if !self
            .type_origin_cache
            .borrow()
            .cached_type_origins
            .contains(&package_id)
        {
            let cached_type_origin_map = &mut self.type_origin_cache.borrow_mut();
            cached_type_origin_map
                .cached_type_origins
                .insert(package_id);
            let original_package_id = pkg.original_package_id();
            let package_types = cached_type_origin_map
                .type_origin_map
                .entry(original_package_id)
                .or_default();
            for ((module_name, type_name), defining_id) in pkg.type_origin_map().into_iter() {
                if let Some(other) = package_types.insert(
                    (module_name.to_string(), type_name.to_string()),
                    defining_id,
                ) {
                    assert_eq!(
                        other, defining_id,
                        "type origin map should never have conflicting entries"
                    );
                }
            }
        }
        Ok(Some(pkg))
    }
    fn fetch_package(&self, id: &ObjectID) -> SuiResult<Option<Rc<MovePackage>>> {
        if let Some(pkg) = self.new_packages.borrow().get(id).cloned() {
            return Ok(Some(pkg));
        }
        if let Some(pkg) = self.package_cache.borrow().get(id).cloned() {
            return Ok(pkg);
        }
        if self.package_cache.borrow().len() >= self.max_package_cache_size {
            self.package_cache.borrow_mut().clear();
        }
        let pkg = self
            .package_store
            .get_package_object(id)?
            .map(|pkg_obj| Rc::new(pkg_obj.move_package().clone()));
        self.package_cache.borrow_mut().insert(*id, pkg.clone());
        Ok(pkg)
    }
}
impl PackageStore for CachedPackageStore<'_> {
    fn get_package(&self, id: &ObjectID) -> SuiResult<Option<Rc<MovePackage>>> {
        self.get_package(id)
    }
    fn resolve_type_to_defining_id(
        &self,
        module_address: ObjectID,
        module_name: &IdentStr,
        type_name: &IdentStr,
    ) -> SuiResult<Option<ObjectID>> {
        let Some(pkg) = self.get_package(&module_address)? else {
            return Ok(None);
        };
        Ok(self
            .type_origin_cache
            .borrow()
            .type_origin_map
            .get(&pkg.original_package_id())
            .and_then(|module_map| {
                module_map
                    .get(&(module_name.to_string(), type_name.to_string()))
                    .copied()
            }))
    }
}