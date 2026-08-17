use std::collections::BTreeMap;
use anchor_lang::prelude::*;
use anchor_spl::token::Token;
use jet_margin::{AdapterResult, MarginAccount};
use crate::state::*;
use crate::Amount;
#[derive(Accounts)]
pub struct MarginWithdraw<'info> {
    #[account(signer)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(mut,
              has_one = vault,
              has_one = deposit_note_mint)]
    pub margin_pool: Account<'info, MarginPool>,
    #[account(mut)]
    pub vault: AccountInfo<'info>,
    #[account(mut)]
    pub deposit_note_mint: UncheckedAccount<'info>,
    #[account(mut)]
    pub source: UncheckedAccount<'info>,
    #[account(mut)]
    pub destination: UncheckedAccount<'info>,
    pub token_program: Program<'info, Token>,
}
pub fn margin_withdraw_handler(ctx: Context<MarginWithdraw>, amount: Amount) -> Result<()> {
    super::withdraw_handler(
        Context::new(
            ctx.program_id,
            &mut super::Withdraw {
                margin_pool: ctx.accounts.margin_pool.clone(),
                vault: ctx.accounts.vault.clone(),
                deposit_note_mint: ctx.accounts.deposit_note_mint.clone(),
                depositor: Signer::try_from(&ctx.accounts.margin_account.to_account_info())?,
                source: ctx.accounts.source.clone(),
                destination: ctx.accounts.destination.clone(),
                token_program: ctx.accounts.token_program.clone(),
            },
            &[],
            BTreeMap::new(),
        ),
        amount,
    )?;
    jet_margin::write_adapter_result(&AdapterResult::NewBalanceChange(vec![ctx
        .accounts
        .source
        .key()]))?;
    Ok(())
}