use anchor_lang::prelude::*;
use anchor_spl::token::{self, Burn, Token, Transfer};
use crate::state::*;
use crate::{Amount, ErrorCode};
#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(mut,
              has_one = vault,
              has_one = deposit_note_mint)]
    pub margin_pool: Account<'info, MarginPool>,
    #[account(mut)]
    pub vault: AccountInfo<'info>,
    #[account(mut)]
    pub deposit_note_mint: UncheckedAccount<'info>,
    pub depositor: Signer<'info>,
    #[account(mut)]
    pub source: UncheckedAccount<'info>,
    #[account(mut)]
    pub destination: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
}
impl<'info> Withdraw<'info> {
    fn transfer_context(&self) -> CpiContext<'_, '_, '_, 'info, Transfer<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            Transfer {
                to: self.destination.to_account_info(),
                from: self.vault.to_account_info(),
                authority: self.margin_pool.to_account_info(),
            },
        )
    }
    fn burn_note_context(&self) -> CpiContext<'_, '_, '_, 'info, Burn<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            Burn {
                to: self.source.to_account_info(),
                mint: self.deposit_note_mint.to_account_info(),
                authority: self.depositor.to_account_info(),
            },
        )
    }
}
pub fn withdraw_handler(ctx: Context<Withdraw>, amount: Amount) -> Result<()> {
    let pool = &mut ctx.accounts.margin_pool;
    let clock = Clock::get()?;
    if !pool.accrue_interest(clock.unix_timestamp) {
        msg!("interest accrual is too far behind");
        return Err(ErrorCode::InterestAccrualBehind.into());
    }
    let withdraw_rounding = RoundingDirection::direction(PoolAction::Withdraw, amount.kind);
    let withdraw_amount = pool.convert_deposit_amount(amount, withdraw_rounding)?;
    pool.withdraw(&withdraw_amount)?;
    let pool = &ctx.accounts.margin_pool;
    let signer = [&pool.signer_seeds()?[..]];
    token::transfer(
        ctx.accounts.transfer_context().with_signer(&signer),
        withdraw_amount.tokens,
    )?;
    token::burn(
        ctx.accounts.burn_note_context().with_signer(&signer),
        withdraw_amount.notes,
    )?;
    Ok(())
}