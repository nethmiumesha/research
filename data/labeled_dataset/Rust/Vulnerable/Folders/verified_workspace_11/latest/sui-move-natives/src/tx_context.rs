use move_binary_format::errors::PartialVMResult;
use move_core_types::{account_address::AccountAddress, gas_algebra::InternalGas};
use move_vm_runtime::{native_charge_gas_early_exit, native_functions::NativeContext};
use move_vm_types::{
    loaded_data::runtime_types::Type, natives::function::NativeResult, pop_arg, values::Value,
};
use smallvec::smallvec;
use std::collections::VecDeque;
use sui_types::{base_types::ObjectID, digests::TransactionDigest};
use crate::{
    NativesCostTable, get_extension, get_extension_mut, object_runtime::ObjectRuntime,
    transaction_context::TransactionContext,
};
#[derive(Clone)]
pub struct TxContextDeriveIdCostParams {
    pub tx_context_derive_id_cost_base: InternalGas,
}
pub fn derive_id(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 2);
    let tx_context_derive_id_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_derive_id_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_derive_id_cost_params.tx_context_derive_id_cost_base
    );
    let ids_created = pop_arg!(args, u64);
    let tx_hash = pop_arg!(args, Vec<u8>);
    let digest = TransactionDigest::try_from(tx_hash.as_slice()).unwrap();
    let address = AccountAddress::from(ObjectID::derive_id(digest, ids_created));
    let obj_runtime: &mut ObjectRuntime = get_extension_mut!(context)?;
    obj_runtime.new_id(address.into())?;
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::address(address)],
    ))
}
#[derive(Clone)]
pub struct TxContextFreshIdCostParams {
    pub tx_context_fresh_id_cost_base: InternalGas,
}
pub fn fresh_id(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_fresh_id_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_fresh_id_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_fresh_id_cost_params.tx_context_fresh_id_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let fresh_id = transaction_context.fresh_id();
    let object_runtime: &mut ObjectRuntime = get_extension_mut!(context)?;
    object_runtime.new_id(fresh_id)?;
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::address(fresh_id.into())],
    ))
}
#[derive(Clone)]
pub struct TxContextSenderCostParams {
    pub tx_context_sender_cost_base: InternalGas,
}
pub fn sender(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_sender_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_sender_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_sender_cost_params.tx_context_sender_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let sender = transaction_context.sender();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::address(sender.into())],
    ))
}
#[derive(Clone)]
pub struct TxContextEpochCostParams {
    pub tx_context_epoch_cost_base: InternalGas,
}
pub fn epoch(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_epoch_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_epoch_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_epoch_cost_params.tx_context_epoch_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let epoch = transaction_context.epoch();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::u64(epoch)],
    ))
}
#[derive(Clone)]
pub struct TxContextEpochTimestampMsCostParams {
    pub tx_context_epoch_timestamp_ms_cost_base: InternalGas,
}
pub fn epoch_timestamp_ms(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_epoch_timestamp_ms_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_epoch_timestamp_ms_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_epoch_timestamp_ms_cost_params.tx_context_epoch_timestamp_ms_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let timestamp = transaction_context.epoch_timestamp_ms();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::u64(timestamp)],
    ))
}
#[derive(Clone)]
pub struct TxContextSponsorCostParams {
    pub tx_context_sponsor_cost_base: InternalGas,
}
pub fn sponsor(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_sponsor_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_sponsor_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_sponsor_cost_params.tx_context_sponsor_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let sponsor = transaction_context
        .sponsor()
        .map(|addr| addr.into())
        .into_iter();
    let sponsor = Value::vector_address(sponsor);
    Ok(NativeResult::ok(context.gas_used(), smallvec![sponsor]))
}
#[derive(Clone)]
pub struct TxContextRGPCostParams {
    pub tx_context_rgp_cost_base: InternalGas,
}
pub fn rgp(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_rgp_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_rgp_cost_params
        .clone();
    native_charge_gas_early_exit!(context, tx_context_rgp_cost_params.tx_context_rgp_cost_base);
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let rgp = transaction_context.rgp();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::u64(rgp)],
    ))
}
#[derive(Clone)]
pub struct TxContextGasPriceCostParams {
    pub tx_context_gas_price_cost_base: InternalGas,
}
pub fn gas_price(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_gas_price_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_gas_price_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_gas_price_cost_params.tx_context_gas_price_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let gas_price = transaction_context.gas_price();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::u64(gas_price)],
    ))
}
#[derive(Clone)]
pub struct TxContextGasBudgetCostParams {
    pub tx_context_gas_budget_cost_base: InternalGas,
}
pub fn gas_budget(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_gas_budget_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_gas_budget_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_gas_budget_cost_params.tx_context_gas_budget_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let gas_budget = transaction_context.gas_budget();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::u64(gas_budget)],
    ))
}
#[derive(Clone)]
pub struct TxContextIdsCreatedCostParams {
    pub tx_context_ids_created_cost_base: InternalGas,
}
pub fn ids_created(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_ids_created_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_ids_created_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_ids_created_cost_params.tx_context_ids_created_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let ids_created = transaction_context.ids_created();
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::u64(ids_created)],
    ))
}
#[derive(Clone)]
pub struct TxContextReplaceCostParams {
    pub tx_context_replace_cost_base: InternalGas,
}
pub fn replace(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    let args_len = args.len();
    debug_assert!(args_len == 8 || args_len == 9);
    let tx_context_replace_cost_params: TxContextReplaceCostParams =
        get_extension!(context, NativesCostTable)?
            .tx_context_replace_cost_params
            .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_replace_cost_params.tx_context_replace_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let mut sponsor: Vec<AccountAddress> = pop_arg!(args, Vec<AccountAddress>);
    let gas_budget: u64 = pop_arg!(args, u64);
    let gas_price: u64 = pop_arg!(args, u64);
    let rgp: u64 = if args_len == 9 {
        pop_arg!(args, u64)
    } else {
        transaction_context.rgp()
    };
    let ids_created: u64 = pop_arg!(args, u64);
    let epoch_timestamp_ms: u64 = pop_arg!(args, u64);
    let epoch: u64 = pop_arg!(args, u64);
    let tx_hash: Vec<u8> = pop_arg!(args, Vec<u8>);
    let sender: AccountAddress = pop_arg!(args, AccountAddress);
    transaction_context.replace(
        sender,
        tx_hash,
        epoch,
        epoch_timestamp_ms,
        ids_created,
        rgp,
        gas_price,
        gas_budget,
        sponsor.pop(),
    )?;
    Ok(NativeResult::ok(context.gas_used(), smallvec![]))
}
const E_NO_IDS_CREATED: u64 = 1;
pub fn last_created_id(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.is_empty());
    let tx_context_derive_id_cost_params = get_extension!(context, NativesCostTable)?
        .tx_context_derive_id_cost_params
        .clone();
    native_charge_gas_early_exit!(
        context,
        tx_context_derive_id_cost_params.tx_context_derive_id_cost_base
    );
    let transaction_context: &mut TransactionContext = get_extension_mut!(context)?;
    let mut ids_created = transaction_context.ids_created();
    if ids_created == 0 {
        return Ok(NativeResult::err(context.gas_used(), E_NO_IDS_CREATED));
    }
    ids_created -= 1;
    let digest = transaction_context.digest();
    let address = AccountAddress::from(ObjectID::derive_id(digest, ids_created));
    let obj_runtime: &mut ObjectRuntime = get_extension_mut!(context)?;
    obj_runtime.new_id(address.into())?;
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::address(address)],
    ))
}