use anchor_lang::prelude::*;
use crate::MarginAccount;
#[derive(Accounts)]
pub struct VerifyHealthy<'info> {
    pub margin_account: AccountLoader<'info, MarginAccount>,
}
pub fn verify_healthy_handler(ctx: Context<VerifyHealthy>) -> Result<()> {
    let account = ctx.accounts.margin_account.load()?;
    account.verify_healthy_positions()?;
    Ok(())
}