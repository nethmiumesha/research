use anchor_lang::prelude::*;
use jet_metadata::MarginAdapterMetadata;
use crate::adapter::{self, CompactAccountMeta, InvokeAdapter};
use crate::{AdapterResult, ErrorCode, MarginAccount};
#[derive(Accounts)]
pub struct AdapterInvoke<'info> {
    pub owner: Signer<'info>,
    #[account(mut, has_one = owner)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    pub adapter_program: AccountInfo<'info>,
    #[account(has_one = adapter_program)]
    pub adapter_metadata: Account<'info, MarginAdapterMetadata>,
}
pub fn adapter_invoke_handler<'info>(
    ctx: Context<'_, '_, '_, 'info, AdapterInvoke<'info>>,
    account_metas: Vec<CompactAccountMeta>,
    data: Vec<u8>,
) -> Result<()> {
    if ctx.accounts.margin_account.load()?.liquidation != Pubkey::default() {
        msg!("account is being liquidated");
        return Err(ErrorCode::Liquidating.into());
    }
    let result = adapter::invoke(
        &InvokeAdapter {
            margin_account: &ctx.accounts.margin_account,
            adapter_program: &ctx.accounts.adapter_program,
            remaining_accounts: ctx.remaining_accounts,
        },
        account_metas,
        data,
    )?;
    let margin_account = ctx.accounts.margin_account.load_mut()?;
    match result {
        AdapterResult::NewBalanceChange(_) => margin_account.verify_healthy_positions()?,
        AdapterResult::PriceChange(_) => (),
        AdapterResult::PriorBalanceChange(_) => (),
    }
    Ok(())
}