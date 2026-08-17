use anchor_lang::prelude::*;
#[derive(Accounts)]
pub struct CreateAuthority<'info> {
    #[account(
        init,
        seeds = [],
        bump,
        payer = payer,
        space = 8 + std::mem::size_of::<Authority>(),
    )]
    authority: Account<'info, Authority>,
    #[account(mut)]
    payer: Signer<'info>,
    system_program: Program<'info, System>,
}
#[account]
#[derive(Default)]
pub struct Authority {
    pub seed: [u8; 1],
}
pub fn create_authority_handler(ctx: Context<CreateAuthority>) -> Result<()> {
    ctx.accounts.authority.seed[0] = *ctx.bumps.get("authority").unwrap();
    Ok(())
}