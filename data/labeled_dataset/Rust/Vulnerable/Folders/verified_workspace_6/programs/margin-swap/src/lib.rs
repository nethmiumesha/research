use anchor_lang::prelude::*;
use anchor_lang::solana_program::program::invoke;
use anchor_spl::token;
use jet_margin::{AdapterResult, MarginAccount};
use jet_margin_pool::{
    cpi::accounts::{Deposit, Withdraw},
    program::JetMarginPool,
    Amount,
};
declare_id!("JPMAa5dnWLFRvUsumawFcGhnwikqZziLLfqn9SLNXPN");
mod instructions;
use instructions::*;
#[program]
mod jet_margin_swap {
    use super::*;
    pub fn margin_swap(
        ctx: Context<MarginSplSwap>,
        amount_in: u64,
        minimum_amount_out: u64,
    ) -> Result<()> {
        margin_spl_swap_handler(ctx, amount_in, minimum_amount_out)
    }
}
#[derive(Accounts)]
pub struct MarginPoolInfo<'info> {
    #[account(mut)]
    pub margin_pool: UncheckedAccount<'info>,
    #[account(mut)]
    pub vault: UncheckedAccount<'info>,
    #[account(mut)]
    pub deposit_note_mint: UncheckedAccount<'info>,
}
#[derive(Copy, Clone)]
pub struct SplTokenSwap;
impl Id for SplTokenSwap {
    fn id() -> Pubkey {
        spl_token_swap::id()
    }
}