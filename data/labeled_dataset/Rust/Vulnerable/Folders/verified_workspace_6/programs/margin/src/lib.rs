use anchor_lang::prelude::*;
use anchor_lang::solana_program::clock::UnixTimestamp;
declare_id!("JPMRGNgRk3w2pzBM1RLNBnpGxQYsFQ3yXKpuk4tTXVZ");
mod adapter;
mod instructions;
mod state;
pub(crate) mod util;
use instructions::*;
pub use state::*;
pub use adapter::{AdapterResult, CompactAccountMeta, PriceChangeInfo};
#[constant]
pub const MIN_COLLATERAL_RATIO: u16 = 12_500;
#[constant]
pub const IDEAL_LIQUIDATION_COLLATERAL_RATIO: u16 = 13_000;
#[constant]
pub const MAX_LIQUIDATION_COLLATERAL_RATIO: u16 = 15_000;
#[constant]
pub const MAX_ORACLE_CONFIDENCE: u16 = 500;
pub const MAX_ORACLE_STALENESS: u64 = 10;
#[constant]
pub const MAX_PRICE_QUOTE_AGE: u64 = 10;
#[constant]
pub const MAX_LIQUIDATION_VALUE_SLIPPAGE: u16 = 500;
#[constant]
pub const MAX_LIQUIDATION_C_RATIO_SLIPPAGE: u16 = 500;
#[constant]
pub const LIQUIDATION_TIMEOUT: UnixTimestamp = 60;
#[program]
pub mod jet_margin {
    use super::*;
    pub fn create_account(ctx: Context<CreateAccount>, seed: u16) -> Result<()> {
        create_account_handler(ctx, seed)
    }
    pub fn close_account(ctx: Context<CloseAccount>) -> Result<()> {
        close_account_handler(ctx)
    }
    pub fn register_position(ctx: Context<RegisterPosition>) -> Result<()> {
        register_position_handler(ctx)
    }
    pub fn update_position_balance(ctx: Context<UpdatePositionBalance>) -> Result<()> {
        update_position_balance_handler(ctx)
    }
    pub fn close_position(ctx: Context<ClosePosition>) -> Result<()> {
        close_position_handler(ctx)
    }
    pub fn verify_healthy(ctx: Context<VerifyHealthy>) -> Result<()> {
        verify_healthy_handler(ctx)
    }
    pub fn adapter_invoke<'info>(
        ctx: Context<'_, '_, '_, 'info, AdapterInvoke<'info>>,
        account_metas: Vec<CompactAccountMeta>,
        data: Vec<u8>,
    ) -> Result<()> {
        adapter_invoke_handler(ctx, account_metas, data)
    }
    pub fn accounting_invoke<'info>(
        ctx: Context<'_, '_, '_, 'info, AccountingInvoke<'info>>,
        account_metas: Vec<CompactAccountMeta>,
        data: Vec<u8>,
    ) -> Result<()> {
        accounting_invoke_handler(ctx, account_metas, data)
    }
    pub fn liquidate_begin(ctx: Context<LiquidateBegin>) -> Result<()> {
        liquidate_begin_handler(ctx)
    }
    pub fn liquidate_end(ctx: Context<LiquidateEnd>) -> Result<()> {
        liquidate_end_handler(ctx)
    }
    pub fn liquidator_invoke<'info>(
        ctx: Context<'_, '_, '_, 'info, LiquidatorInvoke<'info>>,
        account_metas: Vec<CompactAccountMeta>,
        data: Vec<u8>,
    ) -> Result<()> {
        liquidator_invoke_handler(ctx, account_metas, data)
    }
}
#[error_code]
pub enum ErrorCode {
    NoAdapterResult = 135_000,
    WrongProgramAdapterResult = 135_001,
    #[msg("this invocation is not authorized by the necessary accounts")]
    UnauthorizedInvocation,
    #[msg("account cannot record any additional positions")]
    MaxPositions = 135_010,
    #[msg("account has no record of the position")]
    UnknownPosition,
    #[msg("attempting to close a position that has a balance")]
    CloseNonZeroPosition,
    #[msg("attempting to register an existing position")]
    PositionAlreadyRegistered,
    #[msg("attempting to close non-empty margin account")]
    AccountNotEmpty,
    #[msg("attempting to use un-owned position")]
    PositionNotOwned,
    #[msg("wrong adapter to provide the price")]
    InvalidPriceAdapter = 135_020,
    #[msg("a position price is outdated")]
    OutdatedPrice,
    #[msg("an asset price is currently invalid")]
    InvalidPrice,
    #[msg("a position balance is outdated")]
    OutdatedBalance,
    #[msg("the account is not healthy")]
    Unhealthy = 135_030,
    #[msg("the account is already healthy")]
    Healthy,
    #[msg("the account is being liquidated")]
    Liquidating,
    #[msg("the account is not being liquidated")]
    NotLiquidating,
    StalePositions,
    #[msg("the liquidator does not have permission to do this")]
    UnauthorizedLiquidator,
    #[msg("attempted to extract too much value during liquidation")]
    LiquidationLostValue,
    #[msg("reduced the c-ratio too far during liquidation")]
    LiquidationUnhealthy,
    #[msg("increased the c-ratio too high during liquidation")]
    LiquidationTooHealthy,
}
pub fn write_adapter_result(result: &AdapterResult) -> Result<()> {
    let mut adapter_result_data = vec![0u8; 512];
    result.serialize(&mut &mut adapter_result_data[..])?;
    anchor_lang::solana_program::program::set_return_data(&adapter_result_data);
    Ok(())
}