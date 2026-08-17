use anchor_lang::prelude::*;
use anchor_spl::token::{self, Burn, Token, TokenAccount};
use jet_margin::{AdapterResult, MarginAccount};
use crate::state::*;
use crate::{Amount, ErrorCode};
#[derive(Accounts)]
pub struct MarginRepay<'info> {
    #[account(signer)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(mut,
              has_one = deposit_note_mint,
              has_one = loan_note_mint)]
    pub margin_pool: Account<'info, MarginPool>,
    #[account(mut)]
    pub loan_note_mint: AccountInfo<'info>,
    #[account(mut)]
    pub deposit_note_mint: AccountInfo<'info>,
    #[account(mut)]
    pub loan_account: Account<'info, TokenAccount>,
    #[account(mut)]
    pub deposit_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}
impl<'info> MarginRepay<'info> {
    fn burn_loan_context(&self) -> CpiContext<'_, '_, '_, 'info, Burn<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            Burn {
                mint: self.loan_note_mint.to_account_info(),
                to: self.loan_account.to_account_info(),
                authority: self.margin_account.to_account_info(),
            },
        )
    }
    fn burn_deposit_context(&self) -> CpiContext<'_, '_, '_, 'info, Burn<'info>> {
        CpiContext::new(
            self.token_program.to_account_info(),
            Burn {
                to: self.deposit_account.to_account_info(),
                mint: self.deposit_note_mint.to_account_info(),
                authority: self.margin_account.to_account_info(),
            },
        )
    }
}
pub fn margin_repay_handler(ctx: Context<MarginRepay>, amount: Amount) -> Result<()> {
    let pool = &mut ctx.accounts.margin_pool;
    let clock = Clock::get()?;
    if !pool.accrue_interest(clock.unix_timestamp) {
        msg!("interest accrual is too far behind");
        return Err(ErrorCode::InterestAccrualBehind.into());
    }
    let withdraw_rounding = RoundingDirection::direction(PoolAction::Withdraw, amount.kind);
    let withdraw_amount = pool.convert_deposit_amount(amount, withdraw_rounding)?;
    pool.withdraw(&withdraw_amount)?;
    let repay_rounding = RoundingDirection::direction(PoolAction::Repay, amount.kind);
    let repay_amount = pool.convert_loan_amount(amount, repay_rounding)?;
    pool.repay(&repay_amount)?;
    let pool = &ctx.accounts.margin_pool;
    let signer = [&pool.signer_seeds()?[..]];
    token::burn(
        ctx.accounts.burn_loan_context().with_signer(&signer),
        repay_amount.notes,
    )?;
    token::burn(
        ctx.accounts.burn_deposit_context().with_signer(&signer),
        withdraw_amount.notes,
    )?;
    jet_margin::write_adapter_result(&AdapterResult::NewBalanceChange(vec![
        ctx.accounts.loan_account.key(),
        ctx.accounts.deposit_account.key(),
    ]))?;
    Ok(())
}