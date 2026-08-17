use anchor_lang::prelude::*;
use anchor_spl::token::{self, MintTo, Token, TokenAccount};
use jet_margin::{AdapterResult, MarginAccount};
use crate::{state::*, AmountKind};
use crate::{Amount, ErrorCode};
#[derive(Accounts)]
pub struct MarginBorrow<'info> {
    #[account(signer)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(mut,
              has_one = loan_note_mint,
              has_one = deposit_note_mint)]
    pub margin_pool: Account<'info, MarginPool>,
    #[account(mut)]
    pub loan_note_mint: AccountInfo<'info>,
    #[account(mut)]
    pub deposit_note_mint: AccountInfo<'info>,
    #[account(mut, constraint = loan_account.owner == margin_account.key())]
    pub loan_account: Account<'info, TokenAccount>,
    #[account(mut, constraint = deposit_account.owner == margin_account.key())]
    pub deposit_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}
impl<'info> MarginBorrow<'info> {
    fn mint_loan_context(&self) -> CpiContext<'_, '_, '_, 'info, MintTo<'info>> {
        msg!("loan_mint = {:?}", self.loan_note_mint.to_account_info());
        msg!("loan_to = {:?}", self.loan_account.to_account_info());
        msg!("loan_authority = {:?}", self.margin_pool.to_account_info());
        CpiContext::new(
            self.token_program.to_account_info(),
            MintTo {
                mint: self.loan_note_mint.to_account_info(),
                to: self.loan_account.to_account_info(),
                authority: self.margin_pool.to_account_info(),
            },
        )
    }
    fn mint_deposit_context(&self) -> CpiContext<'_, '_, '_, 'info, MintTo<'info>> {
        msg!("deposit_mint = {:?}", self.loan_note_mint.to_account_info());
        msg!("deposit_to = {:?}", self.loan_account.to_account_info());
        msg!(
            "deposit_authority = {:?}",
            self.margin_pool.to_account_info()
        );
        CpiContext::new(
            self.token_program.to_account_info(),
            MintTo {
                to: self.deposit_account.to_account_info(),
                mint: self.deposit_note_mint.to_account_info(),
                authority: self.margin_pool.to_account_info(),
            },
        )
    }
}
pub fn margin_borrow_handler(ctx: Context<MarginBorrow>, token_amount: u64) -> Result<()> {
    let pool = &mut ctx.accounts.margin_pool;
    let clock = Clock::get()?;
    if !pool.accrue_interest(clock.unix_timestamp) {
        msg!("interest accrual is too far behind");
        return Err(ErrorCode::InterestAccrualBehind.into());
    }
    let borrow_rounding = RoundingDirection::direction(PoolAction::Borrow, AmountKind::Tokens);
    let borrow_amount = pool.convert_loan_amount(Amount::tokens(token_amount), borrow_rounding)?;
    pool.borrow(&borrow_amount)?;
    let deposit_rounding = RoundingDirection::direction(PoolAction::Deposit, AmountKind::Tokens);
    let deposit_amount =
        pool.convert_deposit_amount(Amount::tokens(token_amount), deposit_rounding)?;
    pool.deposit(&deposit_amount);
    let pool = &ctx.accounts.margin_pool;
    let signer = [&pool.signer_seeds()?[..]];
    msg!("borrow_amount.notes =  {}", borrow_amount.notes);
    msg!("deposit_amount.notes =  {}\n", deposit_amount.notes);
    token::mint_to(
        ctx.accounts.mint_loan_context().with_signer(&signer),
        borrow_amount.notes,
    )?;
    token::mint_to(
        ctx.accounts.mint_deposit_context().with_signer(&signer),
        deposit_amount.notes,
    )?;
    jet_margin::write_adapter_result(&AdapterResult::NewBalanceChange(vec![
        ctx.accounts.loan_account.key(),
        ctx.accounts.deposit_account.key(),
    ]))?;
    Ok(())
}