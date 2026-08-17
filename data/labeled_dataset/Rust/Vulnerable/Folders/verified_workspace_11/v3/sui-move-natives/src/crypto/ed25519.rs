use crate::{NativesCostTable, get_extension};
use fastcrypto::{
    ed25519::{Ed25519PublicKey, Ed25519Signature},
    traits::{ToFromBytes, VerifyingKey},
};
use move_binary_format::errors::PartialVMResult;
use move_core_types::gas_algebra::InternalGas;
use move_vm_runtime::{native_charge_gas_early_exit, native_functions::NativeContext};
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    pop_arg,
    values::{Value, VectorRef},
};
use smallvec::smallvec;
use std::collections::VecDeque;
const ED25519_BLOCK_SIZE: usize = 128;
#[derive(Clone)]
pub struct Ed25519VerifyCostParams {
    pub ed25519_ed25519_verify_cost_base: InternalGas,
    pub ed25519_ed25519_verify_msg_cost_per_byte: InternalGas,
    pub ed25519_ed25519_verify_msg_cost_per_block: InternalGas,
}
pub fn ed25519_verify(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 3);
    let ed25519_verify_cost_params = get_extension!(context, NativesCostTable)?
        .ed25519_verify_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        ed25519_verify_cost_params.ed25519_ed25519_verify_cost_base
    );
    let msg = pop_arg!(args, VectorRef);
    let msg_ref = msg.as_bytes_ref();
    let public_key_bytes = pop_arg!(args, VectorRef);
    let public_key_bytes_ref = public_key_bytes.as_bytes_ref();
    let signature_bytes = pop_arg!(args, VectorRef);
    let signature_bytes_ref = signature_bytes.as_bytes_ref();
    native_charge_gas_early_exit!(
        context,
        ed25519_verify_cost_params.ed25519_ed25519_verify_msg_cost_per_byte
            * (msg_ref.len() as u64).into()
            + ed25519_verify_cost_params.ed25519_ed25519_verify_msg_cost_per_block
                * (msg_ref.len().div_ceil(ED25519_BLOCK_SIZE) as u64).into()
    );
    let cost = context.gas_used();
    let Ok(signature) = <Ed25519Signature as ToFromBytes>::from_bytes(&signature_bytes_ref) else {
        return Ok(NativeResult::ok(cost, smallvec![Value::bool(false)]));
    };
    let Ok(public_key) = <Ed25519PublicKey as ToFromBytes>::from_bytes(&public_key_bytes_ref)
    else {
        return Ok(NativeResult::ok(cost, smallvec![Value::bool(false)]));
    };
    Ok(NativeResult::ok(
        cost,
        smallvec![Value::bool(public_key.verify(&msg_ref, &signature).is_ok())],
    ))
}