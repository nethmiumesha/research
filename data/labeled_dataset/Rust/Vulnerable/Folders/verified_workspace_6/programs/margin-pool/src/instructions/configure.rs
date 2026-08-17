use anchor_lang::prelude::*;
use crate::state::*;
use jet_metadata::ControlAuthority;
#[derive(Accounts)]
pub struct Configure<'info> {
    #[account(mut)]
    pub margin_pool: Account<'info, MarginPool>,
    #[cfg_attr(not(feature = "devnet"), account(signer))]
    pub authority: Account<'info, ControlAuthority>,
    pub pyth_product: AccountInfo<'info>,
    pub pyth_price: AccountInfo<'info>,
}
pub fn configure_handler(
    ctx: Context<Configure>,
    fee_destination: Option<Pubkey>,
    config: Option<MarginPoolConfig>,
) -> Result<()> {
    let pool = &mut ctx.accounts.margin_pool;
    if let Some(new_fee_destination) = fee_destination {
        pool.fee_destination = new_fee_destination;
    }
    if let Some(new_config) = config {
        pool.config = new_config;
    }
    if *ctx.accounts.pyth_price.key != Pubkey::default() {
        pool.token_price_oracle = ctx.accounts.pyth_price.key();
        msg!("oracle = {}", &pool.token_price_oracle);
    }
    Ok(())
}