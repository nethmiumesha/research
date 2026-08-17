use crate::object_runtime::ObjectRuntime;
use crate::NativesCostTable;
use fastcrypto_zkp::bn254::poseidon::poseidon_bytes;
use move_binary_format::errors::PartialVMResult;
use move_core_types::gas_algebra::InternalGas;
use move_core_types::vm_status::StatusCode;
use move_vm_runtime::{native_charge_gas_early_exit, native_functions::NativeContext};
use move_vm_types::natives::function::PartialVMError;
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    pop_arg,
    values::{Value, VectorRef},
};
use smallvec::smallvec;
use std::collections::VecDeque;
use std::ops::Mul;
pub const NON_CANONICAL_INPUT: u64 = 0;
pub const NOT_SUPPORTED_ERROR: u64 = 1;
fn is_supported(context: &NativeContext) -> bool {
    context
        .extensions()
        .get::<ObjectRuntime>()
        .protocol_config
        .enable_poseidon()
}
#[derive(Clone)]
pub struct PoseidonBN254CostParams {
    pub poseidon_bn254_cost_base: Option<InternalGas>,
    pub poseidon_bn254_data_cost_per_block: Option<InternalGas>,
}
pub fn poseidon_bn254_internal(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    let cost = context.gas_used();
    if !is_supported(context) {
        return Ok(NativeResult::err(cost, NOT_SUPPORTED_ERROR));
    }
    let cost_params = &context
        .extensions()
        .get::<NativesCostTable>()
        .poseidon_bn254_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        cost_params
            .poseidon_bn254_cost_base
            .ok_or_else(
                || PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
                    .with_message("Gas cost for poseidon_bn254 not available".to_string())
            )?
    );
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 1);
    let inputs = pop_arg!(args, VectorRef);
    let length = inputs
        .len(&Type::Vector(Box::new(Type::U8)))?
        .value_as::<u64>()?;
    native_charge_gas_early_exit!(
        context,
        cost_params
            .poseidon_bn254_data_cost_per_block
            .ok_or_else(
                || PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
                    .with_message("Gas cost for poseidon_bn254 not available".to_string())
            )?
            .mul(length.into())
    );
    let field_elements = (0..length)
        .map(|i| {
            let reference = inputs.borrow_elem(i as usize, &Type::Vector(Box::new(Type::U8)))?;
            let value = reference.value_as::<VectorRef>()?.as_bytes_ref().clone();
            Ok(value)
        })
        .collect::<Result<Vec<_>, _>>()?;
    match poseidon_bytes(&field_elements) {
        Ok(result) => Ok(NativeResult::ok(
            context.gas_used(),
            smallvec![Value::vector_u8(result)],
        )),
        Err(_) => Ok(NativeResult::err(context.gas_used(), NON_CANONICAL_INPUT)),
    }
}