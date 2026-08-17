use crate::*;
#[derive(Accounts)]
pub struct MarginSplSwap<'info> {
    #[account(signer)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(mut)]
    pub source_account: AccountInfo<'info>,
    #[account(mut)]
    pub destination_account: AccountInfo<'info>,
    #[account(mut)]
    pub transit_source_account: AccountInfo<'info>,
    #[account(mut)]
    pub transit_destination_account: AccountInfo<'info>,
    pub swap_info: SwapInfo<'info>,
    pub source_margin_pool: MarginPoolInfo<'info>,
    pub destination_margin_pool: MarginPoolInfo<'info>,
    pub margin_pool_program: Program<'info, JetMarginPool>,
    pub token_program: UncheckedAccount<'info>,
}
impl<'info> MarginSplSwap<'info> {
    fn withdraw_source_context(&self) -> CpiContext<'_, '_, '_, 'info, Withdraw<'info>> {
        CpiContext::new(
            self.margin_pool_program.to_account_info(),
            Withdraw {
                margin_pool: self.source_margin_pool.margin_pool.to_account_info(),
                vault: self.source_margin_pool.vault.to_account_info(),
                deposit_note_mint: self.source_margin_pool.deposit_note_mint.to_account_info(),
                depositor: self.margin_account.to_account_info(),
                source: self.source_account.to_account_info(),
                destination: self.transit_source_account.to_account_info(),
                token_program: self.token_program.to_account_info(),
            },
        )
    }
    fn deposit_destination_context(&self) -> CpiContext<'_, '_, '_, 'info, Deposit<'info>> {
        CpiContext::new(
            self.margin_pool_program.to_account_info(),
            Deposit {
                margin_pool: self.destination_margin_pool.margin_pool.to_account_info(),
                vault: self.destination_margin_pool.vault.to_account_info(),
                deposit_note_mint: self
                    .destination_margin_pool
                    .deposit_note_mint
                    .to_account_info(),
                depositor: self.margin_account.to_account_info(),
                source: self.transit_destination_account.to_account_info(),
                destination: self.destination_account.to_account_info(),
                token_program: self.token_program.to_account_info(),
            },
        )
    }
}
#[derive(Accounts)]
pub struct SwapInfo<'info> {
    pub swap_pool: UncheckedAccount<'info>,
    pub authority: UncheckedAccount<'info>,
    #[account(mut)]
    pub vault_into: UncheckedAccount<'info>,
    #[account(mut)]
    pub vault_from: UncheckedAccount<'info>,
    #[account(mut)]
    pub token_mint: UncheckedAccount<'info>,
    #[account(mut)]
    pub fee_account: UncheckedAccount<'info>,
    pub swap_program: Program<'info, SplTokenSwap>,
}
pub fn margin_spl_swap_handler(
    ctx: Context<MarginSplSwap>,
    amount_in: u64,
    minimum_amount_out: u64,
) -> Result<()> {
    jet_margin_pool::cpi::withdraw(
        ctx.accounts.withdraw_source_context(),
        Amount::tokens(amount_in),
    )?;
    let swap_ix = spl_token_swap::instruction::swap(
        ctx.accounts.swap_info.swap_program.key,
        ctx.accounts.token_program.key,
        ctx.accounts.swap_info.swap_pool.key,
        ctx.accounts.swap_info.authority.key,
        &ctx.accounts.margin_account.key(),
        ctx.accounts.transit_source_account.key,
        ctx.accounts.swap_info.vault_into.key,
        ctx.accounts.swap_info.vault_from.key,
        ctx.accounts.transit_destination_account.key,
        ctx.accounts.swap_info.token_mint.key,
        ctx.accounts.swap_info.fee_account.key,
        None,
        spl_token_swap::instruction::Swap {
            amount_in,
            minimum_amount_out,
        },
    )?;
    invoke(
        &swap_ix,
        &[
            ctx.accounts.swap_info.swap_pool.to_account_info(),
            ctx.accounts.swap_info.authority.to_account_info(),
            ctx.accounts.margin_account.to_account_info(),
            ctx.accounts.transit_source_account.to_account_info(),
            ctx.accounts.swap_info.vault_into.to_account_info(),
            ctx.accounts.swap_info.vault_from.to_account_info(),
            ctx.accounts.transit_destination_account.to_account_info(),
            ctx.accounts.swap_info.token_mint.to_account_info(),
            ctx.accounts.swap_info.fee_account.to_account_info(),
            ctx.accounts.token_program.to_account_info(),
        ],
    )?;
    let destination_amount = token::accessor::amount(&ctx.accounts.transit_destination_account)?;
    jet_margin_pool::cpi::deposit(
        ctx.accounts.deposit_destination_context(),
        destination_amount,
    )?;
    jet_margin::write_adapter_result(&AdapterResult::NewBalanceChange(vec![
        ctx.accounts.source_account.key(),
        ctx.accounts.destination_account.key(),
    ]))?;
    Ok(())
}