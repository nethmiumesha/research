use anchor_lang::prelude::*;
mod pc;
use pc::Price;
#[cfg(feature = "mainnet-beta")]
declare_id!("GWXu4vLvXFN87dePFvM7Ejt8HEALEG9GNmwimNKHZrXG");
#[cfg(not(feature = "mainnet-beta"))]
declare_id!("ASfdvRMCan2aoWtbDi5HLXhz2CFfgEkuDoxc57bJLKLX");
#[program]
pub mod pyth {
    use super::*;
    pub fn initialize(ctx: Context<Initialize>, price: i64, expo: i32, conf: u64) -> Result<()> {
        let oracle = &ctx.accounts.price;
        let mut price_oracle = Price::load(oracle).unwrap();
        price_oracle.magic = 0xa1b2c3d4;
        price_oracle.ver = 2;
        price_oracle.atype = 3;
        price_oracle.agg.price = price;
        price_oracle.agg.conf = conf;
        price_oracle.agg.status = pc::PriceStatus::Trading;
        price_oracle.twap = price;
        price_oracle.expo = expo;
        price_oracle.ptype = pc::PriceType::Price;
        Ok(())
    }
    pub fn set_price(ctx: Context<SetPrice>, price: i64, conf: u64) -> Result<()> {
        let oracle = &ctx.accounts.price;
        let mut price_oracle = Price::load(oracle).unwrap();
        let clock = Clock::get().unwrap();
        price_oracle.twap = price;
        price_oracle.agg.price = price;
        price_oracle.agg.conf = conf;
        price_oracle.agg.status = pc::PriceStatus::Trading;
        price_oracle.curr_slot = clock.slot;
        price_oracle.valid_slot = clock.slot;
        Ok(())
    }
}
#[derive(Accounts)]
pub struct SetPrice<'info> {
    #[account(mut)]
    pub price: AccountInfo<'info>,
}
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub price: AccountInfo<'info>,
}