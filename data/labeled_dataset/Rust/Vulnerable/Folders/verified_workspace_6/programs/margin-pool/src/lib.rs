use anchor_lang::prelude::*;
mod instructions;
mod state;
mod util;
use instructions::*;
pub use state::{MarginPool, MarginPoolConfig, PoolFlags};
declare_id!("JPPooLEqRo3NCSx82EdE2VZY5vUaSsgskpZPBHNGVLZ");
pub mod authority {
    use super::*;
    declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");
}
#[program]
mod jet_margin_pool {
    use super::*;
    pub fn create_pool(ctx: Context<CreatePool>) -> Result<()> {
        instructions::create_pool_handler(ctx)
    }
    pub fn configure(
        ctx: Context<Configure>,
        fee_destination: Option<Pubkey>,
        config: Option<MarginPoolConfig>,
    ) -> Result<()> {
        instructions::configure_handler(ctx, fee_destination, config)
    }
    pub fn collect(ctx: Context<Collect>) -> Result<()> {
        instructions::collect_handler(ctx)
    }
    pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
        instructions::deposit_handler(ctx, amount)
    }
    pub fn withdraw(ctx: Context<Withdraw>, amount: Amount) -> Result<()> {
        instructions::withdraw_handler(ctx, amount)
    }
    pub fn margin_borrow(ctx: Context<MarginBorrow>, amount: u64) -> Result<()> {
        instructions::margin_borrow_handler(ctx, amount)
    }
    pub fn margin_repay(ctx: Context<MarginRepay>, amount: Amount) -> Result<()> {
        instructions::margin_repay_handler(ctx, amount)
    }
    pub fn margin_withdraw(ctx: Context<MarginWithdraw>, amount: Amount) -> Result<()> {
        instructions::margin_withdraw_handler(ctx, amount)
    }
    pub fn margin_refresh_position(ctx: Context<MarginRefreshPosition>) -> Result<()> {
        instructions::margin_refresh_position_handler(ctx)
    }
}
#[derive(AnchorSerialize, AnchorDeserialize, Debug, Clone, Copy)]
pub enum AmountKind {
    Tokens,
    Notes,
}
#[derive(AnchorSerialize, AnchorDeserialize, Debug, Clone, Copy)]
pub struct Amount {
    pub kind: AmountKind,
    pub value: u64,
}
impl Amount {
    pub fn tokens(value: u64) -> Self {
        Self {
            kind: AmountKind::Tokens,
            value,
        }
    }
    pub fn notes(value: u64) -> Self {
        Self {
            kind: AmountKind::Notes,
            value,
        }
    }
}
#[error_code]
pub enum ErrorCode {
    #[msg("The pool is currently disabled")]
    Disabled = 135_100,
    #[msg("Interest accrual is too far behind")]
    InterestAccrualBehind,
    #[msg("The pool currently only allows deposits")]
    DepositsOnly,
    #[msg("The pool does not have sufficient liquidity for the transaction")]
    InsufficientLiquidity,
    #[msg("An invalid amount has been supplied")]
    InvalidAmount,
}