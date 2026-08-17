use anchor_lang::prelude::*;
use anchor_spl::token::TokenAccount;
use crate::MarginAccount;
#[derive(Accounts)]
pub struct UpdatePositionBalance<'info> {
    #[account(mut)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    pub token_account: Account<'info, TokenAccount>,
}
pub fn update_position_balance_handler(ctx: Context<UpdatePositionBalance>) -> Result<()> {
    let mut margin_account = ctx.accounts.margin_account.load_mut()?;
    let token_account = &ctx.accounts.token_account;
    margin_account.set_position_balance(
        &token_account.mint,
        &token_account.key(),
        token_account.amount,
    )?;
    Ok(())
}