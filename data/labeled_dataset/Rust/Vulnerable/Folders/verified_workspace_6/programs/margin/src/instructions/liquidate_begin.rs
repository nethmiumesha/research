use anchor_lang::prelude::*;
use jet_proto_math::Number128;
use crate::{
    ErrorCode, Liquidation, MarginAccount, IDEAL_LIQUIDATION_COLLATERAL_RATIO,
    MAX_LIQUIDATION_VALUE_SLIPPAGE,
};
use jet_metadata::LiquidatorMetadata;
#[derive(Accounts)]
pub struct LiquidateBegin<'info> {
    #[account(mut)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub liquidator: Signer<'info>,
    #[account(has_one = liquidator)]
    pub liquidator_metadata: Account<'info, LiquidatorMetadata>,
    #[account(
        init,
        seeds = [
            b"liquidation",
            margin_account.key().as_ref(),
            liquidator.key().as_ref()
        ],
        bump,
        payer = payer,
        space = 8 + std::mem::size_of::<Liquidation>(),
    )]
    pub liquidation: AccountLoader<'info, Liquidation>,
    system_program: Program<'info, System>,
}
pub fn liquidate_begin_handler(ctx: Context<LiquidateBegin>) -> Result<()> {
    let liquidation = &ctx.accounts.liquidation;
    let liquidator = &ctx.accounts.liquidator;
    let mut account = ctx.accounts.margin_account.load_mut()?;
    account.verify_unhealthy_positions()?;
    match account.liquidation {
        liq if liq == liquidation.key() => {
            unreachable!();
        }
        liq if liq == Pubkey::default() => {
            account.start_liquidation(liquidation.key(), liquidator.key());
        }
        _ => {
            return Err(ErrorCode::Liquidating.into());
        }
    }
    let valuation = account.valuation()?;
    let ideal_c_ratio = Number128::from_bps(IDEAL_LIQUIDATION_COLLATERAL_RATIO);
    let ideal_value_liquidated =
        valuation.claims() - valuation.net() / (ideal_c_ratio - Number128::ONE);
    let min_value_change = Number128::ZERO
        - Number128::from_bps(MAX_LIQUIDATION_VALUE_SLIPPAGE) * ideal_value_liquidated;
    *ctx.accounts.liquidation.load_init()? = Liquidation {
        start_time: Clock::get()?.unix_timestamp,
        value_change: Number128::ZERO,
        c_ratio_change: Number128::ZERO,
        min_value_change,
    };
    Ok(())
}