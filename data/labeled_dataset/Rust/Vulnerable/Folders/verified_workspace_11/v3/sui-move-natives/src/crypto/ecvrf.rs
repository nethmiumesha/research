use crate::{NativesCostTable, get_extension};
use fastcrypto::vrf::VRFProof;
use fastcrypto::vrf::ecvrf::{ECVRFProof, ECVRFPublicKey};
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
pub const INVALID_ECVRF_HASH_LENGTH: u64 = 1;
pub const INVALID_ECVRF_PUBLIC_KEY: u64 = 2;
pub const INVALID_ECVRF_PROOF: u64 = 3;
const ECVRF_SHA512_BLOCK_SIZE: usize = 128;
#[derive(Clone)]
pub struct EcvrfEcvrfVerifyCostParams {
    pub ecvrf_ecvrf_verify_cost_base: InternalGas,
    pub ecvrf_ecvrf_verify_alpha_string_cost_per_byte: InternalGas,
    pub ecvrf_ecvrf_verify_alpha_string_cost_per_block: InternalGas,
}
pub fn ecvrf_verify(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 4);
    let ecvrf_ecvrf_verify_cost_params = get_extension!(context, NativesCostTable)?
        .ecvrf_ecvrf_verify_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        ecvrf_ecvrf_verify_cost_params.ecvrf_ecvrf_verify_cost_base
    );
    let proof_bytes = pop_arg!(args, VectorRef);
    let public_key_bytes = pop_arg!(args, VectorRef);
    let alpha_string = pop_arg!(args, VectorRef);
    let hash_bytes = pop_arg!(args, VectorRef);
    let alpha_string_len = alpha_string.as_bytes_ref().len();
    native_charge_gas_early_exit!(
        context,
        ecvrf_ecvrf_verify_cost_params.ecvrf_ecvrf_verify_alpha_string_cost_per_byte
            * (alpha_string_len as u64).into()
            + ecvrf_ecvrf_verify_cost_params.ecvrf_ecvrf_verify_alpha_string_cost_per_block
                * (alpha_string_len.div_ceil(ECVRF_SHA512_BLOCK_SIZE) as u64).into()
    );
    let cost = context.gas_used();
    let Ok(hash) = hash_bytes.as_bytes_ref().as_slice().try_into() else {
        return Ok(NativeResult::err(cost, INVALID_ECVRF_HASH_LENGTH));
    };
    let Ok(public_key) =
        bcs::from_bytes::<ECVRFPublicKey>(public_key_bytes.as_bytes_ref().as_slice())
    else {
        return Ok(NativeResult::err(cost, INVALID_ECVRF_PUBLIC_KEY));
    };
    let Ok(proof) = bcs::from_bytes::<ECVRFProof>(proof_bytes.as_bytes_ref().as_slice()) else {
        return Ok(NativeResult::err(cost, INVALID_ECVRF_PROOF));
    };
    let result = proof.verify_output(alpha_string.as_bytes_ref().as_slice(), &public_key, &hash);
    Ok(NativeResult::ok(
        cost,
        smallvec![Value::bool(result.is_ok())],
    ))
}