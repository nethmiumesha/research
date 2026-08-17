use anchor_lang::prelude::*;
use anchor_spl::token::{self, MintTo, Token, Transfer};
use crate::{state::*, AmountKind};
use crate::{Amount, ErrorCode};
#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(mut,
              has_one = vault,
              has_one = deposit_note_mint)]
    pub margin_pool: Account<'info, MarginPool>,
    #[account(mut)]
    pub vault: UncheckedAccount<'info>,
    #[account(mut)]
    pub deposit_note_mint: UncheckedAccount<'info>,
    pub depositor: Signer<'info>,
    #[account(mut)]
    pub source: UncheckedAccount<'info>,
    #[account(mut)]
    pub destination: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
}
impl<'info> Deposit<'info> {
    fn transfer_source_context(&self) -> CpiContext<'_, '_, '_, 'info, Transfer<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            Transfer {
                to: self.vault.to_account_info(),
                from: self.source.to_account_info(),
                authority: self.depositor.to_account_info(),
            },
        )
    }
    fn mint_note_context(&self) -> CpiContext<'_, '_, '_, 'info, MintTo<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            MintTo {
                to: self.destination.to_account_info(),
                mint: self.deposit_note_mint.to_account_info(),
                authority: self.margin_pool.to_account_info(),
            },
        )
    }
}
pub fn deposit_handler(ctx: Context<Deposit>, token_amount: u64) -> Result<()> {
    let pool = &mut ctx.accounts.margin_pool;
    let clock = Clock::get()?;
    if !pool.accrue_interest(clock.unix_timestamp) {
        msg!("interest accrual is too far behind");
        return Err(ErrorCode::InterestAccrualBehind.into());
    }
    let deposit_rounding = RoundingDirection::direction(PoolAction::Deposit, AmountKind::Tokens);
    let deposit_amount =
        pool.convert_deposit_amount(Amount::tokens(token_amount), deposit_rounding)?;
    pool.deposit(&deposit_amount);
    let pool = &ctx.accounts.margin_pool;
    let signer = [&pool.signer_seeds()?[..]];
    token::transfer(
        ctx.accounts.transfer_source_context().with_signer(&signer),
        deposit_amount.tokens,
    )?;
    token::mint_to(
        ctx.accounts.mint_note_context().with_signer(&signer),
        deposit_amount.notes,
    )?;
    Ok(())
}