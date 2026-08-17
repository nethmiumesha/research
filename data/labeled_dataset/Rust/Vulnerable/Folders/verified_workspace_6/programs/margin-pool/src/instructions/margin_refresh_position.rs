use anchor_lang::prelude::*;
use pyth_client::Price;
use jet_margin::{AdapterResult, MarginAccount, PriceChangeInfo};
use crate::state::*;
#[derive(Accounts)]
pub struct MarginRefreshPosition<'info> {
    #[account(signer)]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    #[account(has_one = token_price_oracle)]
    pub margin_pool: Account<'info, MarginPool>,
    pub token_price_oracle: AccountInfo<'info>,
}
pub fn margin_refresh_position_handler(ctx: Context<MarginRefreshPosition>) -> Result<()> {
    let pool = &ctx.accounts.margin_pool;
    let token_oracle_data = ctx.accounts.token_price_oracle.try_borrow_data()?;
    let token_oracle = bytemuck::from_bytes::<Price>(&token_oracle_data);
    let prices = pool.calculate_prices(token_oracle);
    let deposit_price_info = PriceChangeInfo {
        slot: token_oracle.valid_slot,
        exponent: token_oracle.expo,
        value: prices.deposit_note_price,
        confidence: prices.deposit_note_conf,
        twap: prices.deposit_note_twap,
        mint: pool.deposit_note_mint,
    };
    let loan_price_info = PriceChangeInfo {
        slot: token_oracle.valid_slot,
        exponent: token_oracle.expo,
        value: prices.loan_note_price,
        confidence: prices.loan_note_conf,
        twap: prices.loan_note_twap,
        mint: pool.loan_note_mint,
    };
    jet_margin::write_adapter_result(&AdapterResult::PriceChange(vec![
        deposit_price_info,
        loan_price_info,
    ]))?;
    Ok(())
}