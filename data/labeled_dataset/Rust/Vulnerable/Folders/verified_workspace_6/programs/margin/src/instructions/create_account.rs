use anchor_lang::prelude::*;
use crate::MarginAccount;
#[derive(Accounts)]
#[instruction(seed: u16)]
pub struct CreateAccount<'info> {
    pub owner: Signer<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(init,
              seeds = [owner.key.as_ref(), seed.to_le_bytes().as_ref()],
              bump,
              payer = payer,
              space = 8 + std::mem::size_of::<MarginAccount>(),
    )]
    pub margin_account: AccountLoader<'info, MarginAccount>,
    pub system_program: Program<'info, System>,
}
pub fn create_account_handler(ctx: Context<CreateAccount>, seed: u16) -> Result<()> {
    let mut account = ctx.accounts.margin_account.load_init()?;
    account.initialize(
        *ctx.accounts.owner.key,
        seed,
        *ctx.bumps.get("margin_account").unwrap(),
    );
    Ok(())
}