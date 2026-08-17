use crate::NativesCostTable;
use fastcrypto::error::FastCryptoError;
use move_binary_format::errors::PartialVMResult;
use move_core_types::account_address::AccountAddress;
use move_core_types::gas_algebra::InternalGas;
use move_core_types::u256::U256;
use move_core_types::vm_status::StatusCode;
use move_vm_runtime::{native_charge_gas_early_exit, native_functions::NativeContext};
use move_vm_types::natives::function::PartialVMError;
use move_vm_types::values::VectorRef;
use move_vm_types::{
    loaded_data::runtime_types::Type, natives::function::NativeResult, pop_arg, values::Value,
};
use smallvec::smallvec;
use std::collections::VecDeque;
pub const INVALID_INPUT: u64 = 0;
#[derive(Clone)]
pub struct CheckZkloginIdCostParams {
    pub check_zklogin_id_cost_base: Option<InternalGas>,
}
pub fn check_zklogin_id_internal(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    let check_zklogin_id_cost_params = &context
        .extensions()
        .get::<NativesCostTable>()
        .check_zklogin_id_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        check_zklogin_id_cost_params
            .check_zklogin_id_cost_base
            .ok_or_else(
                || PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
                    .with_message("Gas cost for check_zklogin_id not available".to_string())
            )?
    );
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 6);
    let pin_hash = pop_arg!(args, U256);
    let audience = pop_arg!(args, VectorRef);
    let issuer = pop_arg!(args, VectorRef);
    let key_claim_value = pop_arg!(args, VectorRef);
    let key_claim_name = pop_arg!(args, VectorRef);
    let address = pop_arg!(args, AccountAddress);
    let result = check_id_internal(
        &address,
        &key_claim_name.as_bytes_ref(),
        &key_claim_value.as_bytes_ref(),
        &audience.as_bytes_ref(),
        &issuer.as_bytes_ref(),
        &pin_hash,
    );
    match result {
        Ok(result) => Ok(NativeResult::ok(
            context.gas_used(),
            smallvec![Value::bool(result)],
        )),
        Err(_) => Ok(NativeResult::err(context.gas_used(), INVALID_INPUT)),
    }
}
fn check_id_internal(
    address: &AccountAddress,
    key_claim_name: &[u8],
    key_claim_value: &[u8],
    audience: &[u8],
    issuer: &[u8],
    pin_hash: &U256,
) -> Result<bool, FastCryptoError> {
    match fastcrypto_zkp::bn254::zk_login_api::verify_zk_login_id(
        &address.into_bytes(),
        std::str::from_utf8(key_claim_name).map_err(|_| FastCryptoError::InvalidInput)?,
        std::str::from_utf8(key_claim_value).map_err(|_| FastCryptoError::InvalidInput)?,
        std::str::from_utf8(audience).map_err(|_| FastCryptoError::InvalidInput)?,
        std::str::from_utf8(issuer).map_err(|_| FastCryptoError::InvalidInput)?,
        &pin_hash.to_string(),
    ) {
        Ok(_) => Ok(true),
        Err(FastCryptoError::InvalidProof) => Ok(false),
        Err(_) => Err(FastCryptoError::InvalidInput),
    }
}
#[derive(Clone)]
pub struct CheckZkloginIssuerCostParams {
    pub check_zklogin_issuer_cost_base: Option<InternalGas>,
}
pub fn check_zklogin_issuer_internal(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    let check_zklogin_issuer_cost_params = &context
        .extensions()
        .get::<NativesCostTable>()
        .check_zklogin_issuer_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        check_zklogin_issuer_cost_params
            .check_zklogin_issuer_cost_base
            .ok_or_else(
                || PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
                    .with_message("Gas cost for check_zklogin_issuer not available".to_string())
            )?
    );
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 3);
    let issuer = pop_arg!(args, VectorRef);
    let address_seed = pop_arg!(args, U256);
    let address = pop_arg!(args, AccountAddress);
    let result = check_issuer_internal(&address, &address_seed, &issuer.as_bytes_ref());
    match result {
        Ok(result) => Ok(NativeResult::ok(
            context.gas_used(),
            smallvec![Value::bool(result)],
        )),
        Err(_) => Ok(NativeResult::err(context.gas_used(), INVALID_INPUT)),
    }
}
fn check_issuer_internal(
    address: &AccountAddress,
    address_seed: &U256,
    issuer: &[u8],
) -> Result<bool, FastCryptoError> {
    match fastcrypto_zkp::bn254::zk_login_api::verify_zk_login_iss(
        &address.into_bytes(),
        &address_seed.to_string(),
        std::str::from_utf8(issuer).map_err(|_| FastCryptoError::InvalidInput)?,
    ) {
        Ok(_) => Ok(true),
        Err(FastCryptoError::InvalidProof) => Ok(false),
        Err(_) => Err(FastCryptoError::InvalidInput),
    }
}