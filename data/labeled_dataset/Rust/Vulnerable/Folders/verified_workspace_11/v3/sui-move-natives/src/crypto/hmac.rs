use crate::{NativesCostTable, get_extension};
use fastcrypto::{hmac, traits::ToFromBytes};
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
const HMAC_SHA3_256_BLOCK_SIZE: usize = 136;
#[derive(Clone)]
pub struct HmacHmacSha3256CostParams {
    pub hmac_hmac_sha3_256_cost_base: InternalGas,
    pub hmac_hmac_sha3_256_input_cost_per_byte: InternalGas,
    pub hmac_hmac_sha3_256_input_cost_per_block: InternalGas,
}
pub fn hmac_sha3_256(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 2);
    let hmac_hmac_sha3_256_cost_params = get_extension!(context, NativesCostTable)?
        .hmac_hmac_sha3_256_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        hmac_hmac_sha3_256_cost_params.hmac_hmac_sha3_256_cost_base
    );
    let message = pop_arg!(args, VectorRef);
    let key = pop_arg!(args, VectorRef);
    let msg_len = message.as_bytes_ref().len();
    let key_len = key.as_bytes_ref().len();
    native_charge_gas_early_exit!(
        context,
        hmac_hmac_sha3_256_cost_params.hmac_hmac_sha3_256_input_cost_per_byte
            * ((msg_len + key_len) as u64).into()
            + hmac_hmac_sha3_256_cost_params.hmac_hmac_sha3_256_input_cost_per_block
                * ((((msg_len + key_len) + (2 * HMAC_SHA3_256_BLOCK_SIZE - 2))
                    / HMAC_SHA3_256_BLOCK_SIZE) as u64)
                    .into()
    );
    let hmac_key = hmac::HmacKey::from_bytes(&key.as_bytes_ref())
        .expect("HMAC key can be of any length and from_bytes should always succeed");
    let cost = context.gas_used();
    Ok(NativeResult::ok(
        cost,
        smallvec![Value::vector_u8(
            hmac::hmac_sha3_256(&hmac_key, &message.as_bytes_ref()).to_vec()
        )],
    ))
}