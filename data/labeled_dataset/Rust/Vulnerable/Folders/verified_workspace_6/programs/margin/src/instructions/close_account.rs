use anchor_lang::prelude::*;
use crate::{ErrorCode, MarginAccount};
#[derive(Accounts)]
pub struct CloseAccount<'info> {
    pub owner: Signer<'info>,
    #[account(mut)]
    pub receiver: AccountInfo<'info>,
    #[account(mut,
              close = receiver,
              has_one = owner)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
}
pub fn close_account_handler(ctx: Context<CloseAccount>) -> Result<()> {
    let account = ctx.accounts.margin_account.load()?;
    if account.positions().count() > 0 {
        return Err(ErrorCode::AccountNotEmpty.into());
    }
    Ok(())
}