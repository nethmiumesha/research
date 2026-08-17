use anchor_lang::prelude::*;
declare_id!("DuT6R8tQGYa8ACYXyudFJtxDppSALLcmK39b7918jeSC");
#[program]
pub mod basic_5 {
    use super::*;
    pub fn create(ctx: Context<Create>) -> Result<()> {
        let action_state = &mut ctx.accounts.action_state;
        action_state.user = *ctx.accounts.user.key;
        action_state.action = 0;
        Ok(())
    }
    pub fn walk(ctx: Context<Walk>) -> Result<()> {
        let action_state = &mut ctx.accounts.action_state;
        action_state.action = 1;
        Ok(())
    }
    pub fn run(ctx: Context<Run>) -> Result<()> {
        let action_state = &mut ctx.accounts.action_state;
        action_state.action = 2;
        Ok(())
    }
    pub fn jump(ctx: Context<Jump>) -> Result<()> {
        let action_state = &mut ctx.accounts.action_state;
        action_state.action = 3;
        Ok(())
    }
    pub fn reset(ctx: Context<Reset>) -> Result<()> {
        let action_state = &mut ctx.accounts.action_state;
        action_state.action = 0;
        Ok(())
    }
}
#[derive(Accounts)]
pub struct Create<'info> {
    #[account(
        init,
        payer = user,
        space = 8 + ActionState::INIT_SPACE,
        seeds = [b"action-state", user.key().as_ref()],
        bump
    )]
    pub action_state: Account<'info, ActionState>,
    #[account(mut)]
    pub user: Signer<'info>,
    pub system_program: Program<'info, System>,
}
#[derive(Accounts)]
pub struct Walk<'info> {
    #[account(mut, has_one = user)]
    pub action_state: Account<'info, ActionState>,
    #[account(mut)]
    pub user: Signer<'info>,
}
#[derive(Accounts)]
pub struct Run<'info> {
    #[account(mut, has_one = user)]
    pub action_state: Account<'info, ActionState>,
    #[account(mut)]
    pub user: Signer<'info>,
}
#[derive(Accounts)]
pub struct Jump<'info> {
    #[account(mut, has_one = user)]
    pub action_state: Account<'info, ActionState>,
    #[account(mut)]
    pub user: Signer<'info>,
}
#[derive(Accounts)]
pub struct Reset<'info> {
    #[account(mut, has_one = user)]
    pub action_state: Account<'info, ActionState>,
    #[account(mut)]
    pub user: Signer<'info>,
}
#[account]
#[derive(InitSpace)]
pub struct ActionState {
    pub user: Pubkey,
    pub action: u8,
}