use anchor_lang::prelude::*;
use anchor_spl::token::{Mint, Token, TokenAccount};
use jet_metadata::{PositionTokenMetadata, TokenKind};
use crate::{MarginAccount, PositionKind};
#[derive(Accounts)]
pub struct RegisterPosition<'info> {
    pub authority: Signer<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(mut, constraint = margin_account.load().unwrap().has_authority(authority.key()))]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    pub position_token_mint: Account<'info, Mint>,
    #[account(has_one = position_token_mint)]
    pub metadata: Account<'info, PositionTokenMetadata>,
    #[account(init,
              seeds = [
                  margin_account.key().as_ref(),
                  position_token_mint.key().as_ref()
              ],
              bump,
              payer = payer,
              token::mint = position_token_mint,
              token::authority = margin_account
    )]
    pub token_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
    pub rent: Sysvar<'info, Rent>,
    pub system_program: Program<'info, System>,
}
pub fn register_position_handler(ctx: Context<RegisterPosition>) -> Result<()> {
    let metadata = &ctx.accounts.metadata;
    let mut account = ctx.accounts.margin_account.load_mut()?;
    let position_token = &ctx.accounts.position_token_mint;
    let address = ctx.accounts.token_account.key();
    let kind = match metadata.token_kind {
        TokenKind::NonCollateral => PositionKind::NoValue,
        TokenKind::Collateral => PositionKind::Deposit,
        TokenKind::Claim => PositionKind::Claim,
    };
    account.register_position(
        position_token.key(),
        position_token.decimals,
        address,
        metadata.adapter_program,
        kind,
        metadata.collateral_weight,
        metadata.collateral_max_staleness,
    )?;
    Ok(())
}