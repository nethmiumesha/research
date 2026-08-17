use anchor_lang::prelude::*;
use anchor_spl::token::{Mint, Token, TokenAccount};
use crate::state::*;
use jet_metadata::CONTROL_PROGRAM_ID;
#[derive(Accounts)]
pub struct CreatePool<'info> {
    #[account(
        init,
        seeds = [token_mint.key().as_ref()],
        bump,
        payer = payer,
        space = 8 + std::mem::size_of::<MarginPool>(),
    )]
    pub margin_pool: Box<Account<'info, MarginPool>>,
    #[account(init,
              seeds = [
                margin_pool.key().as_ref(),
                b"vault".as_ref()
              ],
              bump,
              token::mint = token_mint,
              token::authority = margin_pool,
              payer = payer)]
    pub vault: Box<Account<'info, TokenAccount>>,
    #[account(init,
              seeds = [
                margin_pool.key().as_ref(),
                b"deposit-notes".as_ref()
              ],
              bump,
              mint::decimals = token_mint.decimals,
              mint::authority = margin_pool,
              payer = payer)]
    pub deposit_note_mint: Box<Account<'info, Mint>>,
    #[account(init,
              seeds = [
                margin_pool.key().as_ref(),
                b"loan-notes".as_ref()
              ],
              bump,
              mint::decimals = token_mint.decimals,
              mint::authority = margin_pool,
              payer = payer)]
    pub loan_note_mint: Box<Account<'info, Mint>>,
    pub token_mint: Box<Account<'info, Mint>>,
    #[account(owner = CONTROL_PROGRAM_ID)]
    pub authority: Signer<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}
pub fn create_pool_handler(ctx: Context<CreatePool>) -> Result<()> {
    let pool = &mut ctx.accounts.margin_pool;
    pool.address = pool.key();
    pool.pool_bump[0] = *ctx.bumps.get("margin_pool").unwrap();
    pool.token_mint = ctx.accounts.token_mint.key();
    pool.vault = ctx.accounts.vault.key();
    pool.deposit_note_mint = ctx.accounts.deposit_note_mint.key();
    pool.loan_note_mint = ctx.accounts.loan_note_mint.key();
    let clock = Clock::get()?;
    pool.accrued_until = clock.unix_timestamp;
    Ok(())
}