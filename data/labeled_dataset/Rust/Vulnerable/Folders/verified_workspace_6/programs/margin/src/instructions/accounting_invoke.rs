use anchor_lang::prelude::*;
use jet_metadata::MarginAdapterMetadata;
use crate::adapter::{self, CompactAccountMeta, InvokeAdapter};
use crate::{AdapterResult, ErrorCode, MarginAccount};
#[derive(Accounts)]
pub struct AccountingInvoke<'info> {
    #[account(mut)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    pub adapter_program: AccountInfo<'info>,
    #[account(has_one = adapter_program)]
    pub adapter_metadata: Account<'info, MarginAdapterMetadata>,
}
pub fn accounting_invoke_handler<'info>(
    ctx: Context<'_, '_, '_, 'info, AccountingInvoke<'info>>,
    account_metas: Vec<CompactAccountMeta>,
    data: Vec<u8>,
) -> Result<()> {
    let result = adapter::invoke(
        &InvokeAdapter {
            margin_account: &ctx.accounts.margin_account,
            adapter_program: &ctx.accounts.adapter_program,
            remaining_accounts: ctx.remaining_accounts,
        },
        account_metas,
        data,
    )?;
    match result {
        AdapterResult::NewBalanceChange(_) => {
            msg!("New balance changes may only be realized through either adapter_invoke or liquidate_invoke, depending on context.");
            err!(ErrorCode::UnauthorizedInvocation)
        }
        AdapterResult::PriceChange(_) => Ok(()),
        AdapterResult::PriorBalanceChange(_) => Ok(()),
    }
}