use crate::{
    NativesCostTable, abstract_size, charge_cache_or_load_gas, get_extension, get_extension_mut,
    get_nested_struct_field, get_object_id,
    object_runtime::{
        ObjectRuntime,
        object_store::{CacheInfo, ObjectResult},
    },
};
use move_binary_format::errors::{PartialVMError, PartialVMResult};
use move_core_types::{
    account_address::AccountAddress,
    gas_algebra::InternalGas,
    language_storage::{StructTag, TypeTag},
    vm_status::StatusCode,
};
use move_vm_runtime::native_charge_gas_early_exit;
use move_vm_runtime::native_functions::NativeContext;
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    pop_arg,
    values::{StructRef, Value},
    views::{SizeConfig, ValueView},
};
use smallvec::smallvec;
use std::collections::VecDeque;
use sui_types::{base_types::MoveObjectType, dynamic_field::derive_dynamic_field_id};
use tracing::instrument;
const E_KEY_DOES_NOT_EXIST: u64 = 1;
const E_FIELD_TYPE_MISMATCH: u64 = 2;
const E_BCS_SERIALIZATION_FAILURE: u64 = 3;
const PRE_EXISTING_ABSTRACT_SIZE: u64 = 2;
const BORROW_ABSTRACT_SIZE: u64 = 8;
macro_rules! get_or_fetch_object {
    ($context:ident, $ty_args:ident, $parent:ident, $child_id:ident, $ty_cost_per_byte:expr) => {{
        let child_ty = $ty_args.pop().unwrap();
        native_charge_gas_early_exit!(
            $context,
            $ty_cost_per_byte * u64::from(child_ty.size()).into()
        );
        assert!($ty_args.is_empty());
        let (tag, layout, annotated_layout) = match crate::get_tag_and_layouts($context, &child_ty)?
        {
            Some(res) => res,
            None => {
                return Ok(NativeResult::err(
                    $context.gas_used(),
                    E_BCS_SERIALIZATION_FAILURE,
                ));
            }
        };
        let object_runtime: &mut ObjectRuntime = $crate::get_extension_mut!($context)?;
        object_runtime.get_or_fetch_child_object(
            $parent,
            $child_id,
            &layout,
            &annotated_layout,
            MoveObjectType::from(tag),
        )?
    }};
}
#[derive(Clone)]
pub struct DynamicFieldHashTypeAndKeyCostParams {
    pub dynamic_field_hash_type_and_key_cost_base: InternalGas,
    pub dynamic_field_hash_type_and_key_type_cost_per_byte: InternalGas,
    pub dynamic_field_hash_type_and_key_value_cost_per_byte: InternalGas,
    pub dynamic_field_hash_type_and_key_type_tag_cost_per_byte: InternalGas,
}
#[instrument(level = "trace", skip_all)]
pub fn hash_type_and_key(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    assert_eq!(ty_args.len(), 1);
    assert_eq!(args.len(), 2);
    let dynamic_field_hash_type_and_key_cost_params = get_extension!(context, NativesCostTable)?
        .dynamic_field_hash_type_and_key_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_hash_type_and_key_cost_params.dynamic_field_hash_type_and_key_cost_base
    );
    let k_ty = ty_args.pop().unwrap();
    let k: Value = args.pop_back().unwrap();
    let parent = pop_arg!(args, AccountAddress);
    let k_ty_size = u64::from(k_ty.size());
    let k_value_size = u64::from(abstract_size(
        get_extension!(context, ObjectRuntime)?.protocol_config,
        &k,
    )?);
    native_charge_gas_early_exit!(
        context,
        dynamic_field_hash_type_and_key_cost_params
            .dynamic_field_hash_type_and_key_type_cost_per_byte
            * k_ty_size.into()
            + dynamic_field_hash_type_and_key_cost_params
                .dynamic_field_hash_type_and_key_value_cost_per_byte
                * k_value_size.into()
    );
    let k_tag = context.type_to_type_tag(&k_ty)?;
    let k_tag_size = u64::from(k_tag.abstract_size_for_gas_metering());
    native_charge_gas_early_exit!(
        context,
        dynamic_field_hash_type_and_key_cost_params
            .dynamic_field_hash_type_and_key_type_tag_cost_per_byte
            * k_tag_size.into()
    );
    let cost = context.gas_used();
    let k_layout = match context.type_to_type_layout(&k_ty) {
        Ok(Some(layout)) => layout,
        _ => return Ok(NativeResult::err(cost, E_BCS_SERIALIZATION_FAILURE)),
    };
    let Some(k_bytes) = k.typed_serialize(&k_layout) else {
        return Ok(NativeResult::err(cost, E_BCS_SERIALIZATION_FAILURE));
    };
    let Ok(id) = derive_dynamic_field_id(parent, &k_tag, &k_bytes) else {
        return Ok(NativeResult::err(cost, E_BCS_SERIALIZATION_FAILURE));
    };
    Ok(NativeResult::ok(cost, smallvec![Value::address(id.into())]))
}
#[derive(Clone)]
pub struct DynamicFieldAddChildObjectCostParams {
    pub dynamic_field_add_child_object_cost_base: InternalGas,
    pub dynamic_field_add_child_object_type_cost_per_byte: InternalGas,
    pub dynamic_field_add_child_object_value_cost_per_byte: InternalGas,
    pub dynamic_field_add_child_object_struct_tag_cost_per_byte: InternalGas,
}
#[instrument(level = "trace", skip_all)]
pub fn add_child_object(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    assert!(ty_args.len() == 1);
    assert!(args.len() == 2);
    let dynamic_field_add_child_object_cost_params = get_extension!(context, NativesCostTable)?
        .dynamic_field_add_child_object_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_add_child_object_cost_params.dynamic_field_add_child_object_cost_base
    );
    let child = args.pop_back().unwrap();
    let parent = pop_arg!(args, AccountAddress).into();
    assert!(args.is_empty());
    let protocol_config = get_extension!(context, ObjectRuntime)?.protocol_config;
    let child_value_size = if protocol_config.abstract_size_in_object_runtime() {
        PRE_EXISTING_ABSTRACT_SIZE
    } else {
        child.legacy_size().into()
    };
    native_charge_gas_early_exit!(
        context,
        dynamic_field_add_child_object_cost_params
            .dynamic_field_add_child_object_value_cost_per_byte
            * child_value_size.into()
    );
    let child_id = get_object_id(child.copy_value().unwrap())
        .unwrap()
        .value_as::<AccountAddress>()
        .unwrap()
        .into();
    let child_ty = ty_args.pop().unwrap();
    let child_type_size = u64::from(child_ty.size());
    native_charge_gas_early_exit!(
        context,
        dynamic_field_add_child_object_cost_params
            .dynamic_field_add_child_object_type_cost_per_byte
            * child_type_size.into()
    );
    assert!(ty_args.is_empty());
    let tag = match context.type_to_type_tag(&child_ty)? {
        TypeTag::Struct(s) => *s,
        _ => {
            return Err(
                PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
                    .with_message("Sui verifier guarantees this is a struct".to_string()),
            );
        }
    };
    let struct_tag_size = u64::from(tag.abstract_size_for_gas_metering());
    native_charge_gas_early_exit!(
        context,
        dynamic_field_add_child_object_cost_params
            .dynamic_field_add_child_object_struct_tag_cost_per_byte
            * struct_tag_size.into()
    );
    if get_extension!(context, ObjectRuntime)?
        .protocol_config
        .generate_df_type_layouts()
    {
        context.type_to_type_layout(&child_ty)?;
    }
    let object_runtime: &mut ObjectRuntime = get_extension_mut!(context)?;
    object_runtime.add_child_object(parent, child_id, MoveObjectType::from(tag), child)?;
    Ok(NativeResult::ok(context.gas_used(), smallvec![]))
}
#[derive(Clone)]
pub struct DynamicFieldBorrowChildObjectCostParams {
    pub dynamic_field_borrow_child_object_cost_base: InternalGas,
    pub dynamic_field_borrow_child_object_child_ref_cost_per_byte: InternalGas,
    pub dynamic_field_borrow_child_object_type_cost_per_byte: InternalGas,
}
#[instrument(level = "trace", skip_all)]
pub fn borrow_child_object(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    assert!(ty_args.len() == 1);
    assert!(args.len() == 2);
    let dynamic_field_borrow_child_object_cost_params = get_extension!(context, NativesCostTable)?
        .dynamic_field_borrow_child_object_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_borrow_child_object_cost_params.dynamic_field_borrow_child_object_cost_base
    );
    let child_id = pop_arg!(args, AccountAddress).into();
    let parent_uid = pop_arg!(args, StructRef).read_ref().unwrap();
    let parent = get_nested_struct_field(parent_uid, &[0, 0])
        .unwrap()
        .value_as::<AccountAddress>()
        .unwrap()
        .into();
    assert!(args.is_empty());
    let global_value_result = get_or_fetch_object!(
        context,
        ty_args,
        parent,
        child_id,
        dynamic_field_borrow_child_object_cost_params
            .dynamic_field_borrow_child_object_type_cost_per_byte
    );
    let (cache_info, global_value) = match global_value_result {
        ObjectResult::MismatchedType => {
            return Ok(NativeResult::err(context.gas_used(), E_FIELD_TYPE_MISMATCH));
        }
        ObjectResult::Loaded(gv) => gv,
    };
    if !global_value.exists()? {
        return Ok(NativeResult::err(context.gas_used(), E_KEY_DOES_NOT_EXIST));
    }
    let child_ref = global_value.borrow_global().inspect_err(|err| {
        assert!(err.major_status() != StatusCode::MISSING_DATA);
    })?;
    charge_cache_or_load_gas!(context, cache_info);
    let protocol_config = get_extension!(context, ObjectRuntime)?.protocol_config;
    let child_ref_size = match cache_info {
        _ if !protocol_config.abstract_size_in_object_runtime() => child_ref.legacy_size(),
        CacheInfo::CachedValue => {
            BORROW_ABSTRACT_SIZE.into()
        }
        CacheInfo::CachedObject | CacheInfo::Loaded(_) => {
            child_ref.abstract_memory_size(&SizeConfig {
                include_vector_size: true,
                traverse_references: true,
                fine_grained_value_size: true,
            })?
        }
    };
    native_charge_gas_early_exit!(
        context,
        dynamic_field_borrow_child_object_cost_params
            .dynamic_field_borrow_child_object_child_ref_cost_per_byte
            * u64::from(child_ref_size).into()
    );
    Ok(NativeResult::ok(context.gas_used(), smallvec![child_ref]))
}
#[derive(Clone)]
pub struct DynamicFieldRemoveChildObjectCostParams {
    pub dynamic_field_remove_child_object_cost_base: InternalGas,
    pub dynamic_field_remove_child_object_child_cost_per_byte: InternalGas,
    pub dynamic_field_remove_child_object_type_cost_per_byte: InternalGas,
}
#[instrument(level = "trace", skip_all)]
pub fn remove_child_object(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    assert!(ty_args.len() == 1);
    assert!(args.len() == 2);
    let dynamic_field_remove_child_object_cost_params = get_extension!(context, NativesCostTable)?
        .dynamic_field_remove_child_object_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_remove_child_object_cost_params.dynamic_field_remove_child_object_cost_base
    );
    let child_id = pop_arg!(args, AccountAddress).into();
    let parent = pop_arg!(args, AccountAddress).into();
    assert!(args.is_empty());
    let global_value_result = get_or_fetch_object!(
        context,
        ty_args,
        parent,
        child_id,
        dynamic_field_remove_child_object_cost_params
            .dynamic_field_remove_child_object_type_cost_per_byte
    );
    let (cache_info, global_value) = match global_value_result {
        ObjectResult::MismatchedType => {
            return Ok(NativeResult::err(context.gas_used(), E_FIELD_TYPE_MISMATCH));
        }
        ObjectResult::Loaded(gv) => gv,
    };
    if !global_value.exists()? {
        return Ok(NativeResult::err(context.gas_used(), E_KEY_DOES_NOT_EXIST));
    }
    let child = global_value.move_from().inspect_err(|err| {
        assert!(err.major_status() != StatusCode::MISSING_DATA);
    })?;
    charge_cache_or_load_gas!(context, cache_info);
    let protocol_config = get_extension!(context, ObjectRuntime)?.protocol_config;
    let child_size = match cache_info {
        _ if !protocol_config.abstract_size_in_object_runtime() => child.legacy_size(),
        CacheInfo::CachedValue => {
            PRE_EXISTING_ABSTRACT_SIZE.into()
        }
        CacheInfo::CachedObject | CacheInfo::Loaded(_) => {
            child.abstract_memory_size(&SizeConfig {
                include_vector_size: true,
                traverse_references: false,
                fine_grained_value_size: true,
            })?
        }
    };
    native_charge_gas_early_exit!(
        context,
        dynamic_field_remove_child_object_cost_params
            .dynamic_field_remove_child_object_child_cost_per_byte
            * u64::from(child_size).into()
    );
    Ok(NativeResult::ok(context.gas_used(), smallvec![child]))
}
#[derive(Clone)]
pub struct DynamicFieldHasChildObjectCostParams {
    pub dynamic_field_has_child_object_cost_base: InternalGas,
}
#[instrument(level = "trace", skip_all)]
pub fn has_child_object(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    assert!(ty_args.is_empty());
    assert!(args.len() == 2);
    let dynamic_field_has_child_object_cost_params = get_extension!(context, NativesCostTable)?
        .dynamic_field_has_child_object_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_has_child_object_cost_params.dynamic_field_has_child_object_cost_base
    );
    let child_id = pop_arg!(args, AccountAddress).into();
    let parent = pop_arg!(args, AccountAddress).into();
    let object_runtime: &mut ObjectRuntime = get_extension_mut!(context)?;
    let (cache_info, has_child) = object_runtime.child_object_exists(parent, child_id)?;
    charge_cache_or_load_gas!(context, cache_info);
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::bool(has_child)],
    ))
}
#[derive(Clone)]
pub struct DynamicFieldHasChildObjectWithTyCostParams {
    pub dynamic_field_has_child_object_with_ty_cost_base: InternalGas,
    pub dynamic_field_has_child_object_with_ty_type_cost_per_byte: InternalGas,
    pub dynamic_field_has_child_object_with_ty_type_tag_cost_per_byte: InternalGas,
}
#[instrument(level = "trace", skip_all)]
pub fn has_child_object_with_ty(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    assert!(ty_args.len() == 1);
    assert!(args.len() == 2);
    let dynamic_field_has_child_object_with_ty_cost_params =
        get_extension!(context, NativesCostTable)?
            .dynamic_field_has_child_object_with_ty_cost_params
            .clone();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_has_child_object_with_ty_cost_params
            .dynamic_field_has_child_object_with_ty_cost_base
    );
    let child_id = pop_arg!(args, AccountAddress).into();
    let parent = pop_arg!(args, AccountAddress).into();
    assert!(args.is_empty());
    let ty = ty_args.pop().unwrap();
    native_charge_gas_early_exit!(
        context,
        dynamic_field_has_child_object_with_ty_cost_params
            .dynamic_field_has_child_object_with_ty_type_cost_per_byte
            * u64::from(ty.size()).into()
    );
    let tag: StructTag = match context.type_to_type_tag(&ty)? {
        TypeTag::Struct(s) => *s,
        _ => {
            return Err(
                PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
                    .with_message("Sui verifier guarantees this is a struct".to_string()),
            );
        }
    };
    native_charge_gas_early_exit!(
        context,
        dynamic_field_has_child_object_with_ty_cost_params
            .dynamic_field_has_child_object_with_ty_type_tag_cost_per_byte
            * u64::from(tag.abstract_size_for_gas_metering()).into()
    );
    let object_runtime: &mut ObjectRuntime = get_extension_mut!(context)?;
    let (cache_info, has_child) = object_runtime.child_object_exists_and_has_type(
        parent,
        child_id,
        &MoveObjectType::from(tag),
    )?;
    charge_cache_or_load_gas!(context, cache_info);
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::bool(has_child)],
    ))
}