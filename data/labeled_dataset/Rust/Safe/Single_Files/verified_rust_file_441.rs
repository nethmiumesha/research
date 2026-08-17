use crate::{constants::ANCHOR_DISCRIMINATOR_SIZE, state::Provider};
use anchor_lang::prelude::*;
#[derive(Accounts)]
pub struct RegisterProvider<'info> {
    #[account(mut)]
    payer: Signer<'info>,
    #[account(
        init,
        payer = payer,
        space = ANCHOR_DISCRIMINATOR_SIZE + Provider::INIT_SPACE,
    )]
    provider: Account<'info, Provider>,
    system_program: Program<'info, System>,
}
pub fn register_provider(
    ctx: Context<RegisterProvider>,
    name: String,
    ip: String,
    port: u16,
    country: String,
    environment_type: String,
    availability: bool,
) -> Result<()> {
    *ctx.accounts.provider = Provider {
        name,
        ip,
        port,
        country,
        environment_type,
        availability
    };
    Ok(())
}