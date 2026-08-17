use anchor_lang::prelude::*;
use crate::{
    constants::INITIAL_REPUTATION_SCORE,
    enums::ScoutStatus,
    errors::scout::ScoutRewardsError,
    events::scout::ScoutRegistered,
    states::scout::{ Scout, ScoutConfig },
};
#[derive(Accounts)]
pub struct RegisterScout<'info> {
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(
        init,
        payer = user,
        space = Scout::LEN,
        seeds = [b"scout", user.key().as_ref()],
        bump
    )]
    pub scout: Account<'info, crate::states::scout::Scout>,
    #[account(seeds = [b"scout_config"], bump)]
    pub scout_config: Account<'info, ScoutConfig>,
    pub system_program: Program<'info, System>,
}
pub fn register_scout_handler(ctx: Context<RegisterScout>, stake_amount: u64) -> Result<()> {
    let scout_config = &ctx.accounts.scout_config;
    let scout_account = &mut ctx.accounts.scout;
    let clock = Clock::get()?;
    if stake_amount < scout_config.minimum_stake {
        return Err(ScoutRewardsError::InsufficientStake.into());
    }
    scout_account.owner = ctx.accounts.user.key();
    scout_account.status = ScoutStatus::Active;
    scout_account.staked_amount = stake_amount;
    scout_account.reputation_score = INITIAL_REPUTATION_SCORE;
    scout_account.properties_submitted = 0;
    scout_account.properties_verified = 0;
    scout_account.properties_disputed = 0;
    scout_account.registration_at = clock.unix_timestamp;
    scout_account.last_active_at = clock.unix_timestamp;
    scout_account.cooldown_start = None;
    scout_account.bump = ctx.bumps.scout;
    emit!(ScoutRegistered {
        scout: ctx.accounts.user.key(),
        stake_amount,
        timestamp: clock.unix_timestamp,
    });
    Ok(())
}