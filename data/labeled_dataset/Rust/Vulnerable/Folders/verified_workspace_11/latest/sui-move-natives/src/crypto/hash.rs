use crate::{NativesCostTable, get_extension};
use fastcrypto::hash::{Blake2b256, HashFunction, Keccak256};
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
use std::{collections::VecDeque, ops::Mul};
const BLAKE_2B256_BLOCK_SIZE: u16 = 128;
const KECCAK_256_BLOCK_SIZE: u16 = 136;
fn hash<H: HashFunction<DIGEST_SIZE>, const DIGEST_SIZE: usize>(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
    msg_cost_per_byte: InternalGas,
    msg_cost_per_block: InternalGas,
    block_size: u16,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 1);
    let msg = pop_arg!(args, VectorRef);
    let msg_ref = msg.as_bytes_ref();
    let block_size = block_size as usize;
    native_charge_gas_early_exit!(
        context,
        msg_cost_per_byte.mul((msg_ref.len() as u64).into())
            + msg_cost_per_block
                .mul((msg_ref.len().div_ceil(block_size) as u64).into())
    );
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::vector_u8(
            H::digest(msg.as_bytes_ref().as_slice()).digest
        )],
    ))
}
#[derive(Clone)]
pub struct HashKeccak256CostParams {
    pub hash_keccak256_cost_base: InternalGas,
    pub hash_keccak256_data_cost_per_byte: InternalGas,
    pub hash_keccak256_data_cost_per_block: InternalGas,
}
pub fn keccak256(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    let hash_keccak256_cost_params = get_extension!(context, NativesCostTable)?
        .hash_keccak256_cost_params
        .clone();
    native_charge_gas_early_exit!(context, hash_keccak256_cost_params.hash_keccak256_cost_base);
    hash::<Keccak256, 32>(
        context,
        ty_args,
        args,
        hash_keccak256_cost_params.hash_keccak256_data_cost_per_byte,
        hash_keccak256_cost_params.hash_keccak256_data_cost_per_block,
        KECCAK_256_BLOCK_SIZE,
    )
}
#[derive(Clone)]
pub struct HashBlake2b256CostParams {
    pub hash_blake2b256_cost_base: InternalGas,
    pub hash_blake2b256_data_cost_per_byte: InternalGas,
    pub hash_blake2b256_data_cost_per_block: InternalGas,
}
pub fn blake2b256(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    let hash_blake2b256_cost_params = get_extension!(context, NativesCostTable)?
        .hash_blake2b256_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        hash_blake2b256_cost_params.hash_blake2b256_cost_base
    );
    hash::<Blake2b256, 32>(
        context,
        ty_args,
        args,
        hash_blake2b256_cost_params.hash_blake2b256_data_cost_per_byte,
        hash_blake2b256_cost_params.hash_blake2b256_data_cost_per_block,
        BLAKE_2B256_BLOCK_SIZE,
    )
}