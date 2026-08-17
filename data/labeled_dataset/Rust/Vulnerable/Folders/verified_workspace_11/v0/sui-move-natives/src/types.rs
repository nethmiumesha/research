use move_binary_format::errors::PartialVMResult;
use move_core_types::{
    gas_algebra::InternalGas,
    language_storage::TypeTag,
    runtime_value::{MoveStructLayout, MoveTypeLayout},
};
use move_vm_runtime::{native_charge_gas_early_exit, native_functions::NativeContext};
use move_vm_types::{
    loaded_data::runtime_types::Type, natives::function::NativeResult, values::Value,
};
use smallvec::smallvec;
use std::collections::VecDeque;
use crate::NativesCostTable;
pub(crate) fn is_otw_struct(struct_layout: &MoveStructLayout, type_tag: &TypeTag) -> bool {
    let has_one_bool_field = matches!(struct_layout.0.as_slice(), [MoveTypeLayout::Bool]);
    matches!(
        type_tag,
        TypeTag::Struct(struct_tag) if has_one_bool_field && struct_tag.name.to_string() == struct_tag.module.to_string().to_ascii_uppercase())
}
#[derive(Clone)]
pub struct TypesIsOneTimeWitnessCostParams {
    pub types_is_one_time_witness_cost_base: InternalGas,
    pub types_is_one_time_witness_type_tag_cost_per_byte: InternalGas,
    pub types_is_one_time_witness_type_cost_per_byte: InternalGas,
}
pub fn is_one_time_witness(
    context: &mut NativeContext,
    mut ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.len() == 1);
    debug_assert!(args.len() == 1);
    let type_is_one_time_witness_cost_params = context
        .extensions_mut()
        .get::<NativesCostTable>()
        .type_is_one_time_witness_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        type_is_one_time_witness_cost_params.types_is_one_time_witness_cost_base
    );
    let ty = ty_args.pop().unwrap();
    native_charge_gas_early_exit!(
        context,
        type_is_one_time_witness_cost_params.types_is_one_time_witness_type_cost_per_byte
            * u64::from(ty.size()).into()
    );
    let type_tag = context.type_to_type_tag(&ty)?;
    native_charge_gas_early_exit!(
        context,
        type_is_one_time_witness_cost_params.types_is_one_time_witness_type_tag_cost_per_byte
            * u64::from(type_tag.abstract_size_for_gas_metering()).into()
    );
    let type_layout = context.type_to_type_layout(&ty)?;
    let cost = context.gas_used();
    let Some(MoveTypeLayout::Struct(struct_layout)) = type_layout else {
        return Ok(NativeResult::ok(cost, smallvec![Value::bool(false)]));
    };
    let is_otw = is_otw_struct(&struct_layout, &type_tag);
    Ok(NativeResult::ok(cost, smallvec![Value::bool(is_otw)]))
}