use anchor_lang::prelude::*;
use anchor_lang::AccountsClose;
use crate::{ErrorCode, Liquidation, MarginAccount, LIQUIDATION_TIMEOUT};
#[derive(Accounts)]
pub struct LiquidateEnd<'info> {
    pub authority: Signer<'info>,
    #[account(mut, has_one = liquidation)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(mut)]
    pub liquidation: AccountLoader<'info, Liquidation>,
}
pub fn liquidate_end_handler(ctx: Context<LiquidateEnd>) -> Result<()> {
    let mut account = ctx.accounts.margin_account.load_mut()?;
    let start_time = ctx.accounts.liquidation.load()?.start_time;
    if (account.liquidator != ctx.accounts.authority.key())
        && Clock::get()?.unix_timestamp - start_time < LIQUIDATION_TIMEOUT
    {
        msg!(
            "Only the liquidator may end the liquidation before the timeout of {} seconds",
            LIQUIDATION_TIMEOUT
        );
        return Err(ErrorCode::UnauthorizedLiquidator.into());
    }
    account.end_liquidation();
    ctx.accounts
        .liquidation
        .close(ctx.accounts.authority.to_account_info())?;
    Ok(())
}