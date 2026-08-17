use anchor_lang::prelude::*;
use anchor_spl::token::{self, CloseAccount, Mint, Token, TokenAccount};
use crate::MarginAccount;
#[derive(Accounts)]
pub struct ClosePosition<'info> {
    pub authority: Signer<'info>,
    #[account(mut)]
    pub receiver: AccountInfo<'info>,
    #[account(mut, constraint = margin_account.load().unwrap().has_authority(authority.key()))]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    pub position_token_mint: Account<'info, Mint>,
    #[account(mut)]
    pub token_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}
impl<'info> ClosePosition<'info> {
    fn close_token_account_ctx(&self) -> CpiContext<'_, '_, '_, 'info, CloseAccount<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            CloseAccount {
                account: self.token_account.to_account_info(),
                authority: self.margin_account.to_account_info(),
                destination: self.receiver.to_account_info(),
            },
        )
    }
}
pub fn close_position_handler(ctx: Context<ClosePosition>) -> Result<()> {
    ctx.accounts
        .margin_account
        .load_mut()?
        .unregister_position(
            &ctx.accounts.position_token_mint.key(),
            &ctx.accounts.token_account.key(),
        )?;
    let account = ctx.accounts.margin_account.load()?;
    token::close_account(
        ctx.accounts
            .close_token_account_ctx()
            .with_signer(&[&account.signer_seeds()]),
    )?;
    Ok(())
}