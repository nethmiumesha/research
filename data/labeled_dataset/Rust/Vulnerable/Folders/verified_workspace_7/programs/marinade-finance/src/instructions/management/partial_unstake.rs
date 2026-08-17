use crate::{
    checks::check_stake_amount_and_validator,
    error::MarinadeError,
    state::{
        stake_system::{StakeList, StakeSystem},
        validator_system::ValidatorList,
    },
    State,
};
use std::convert::TryFrom;
use anchor_lang::prelude::*;
use anchor_lang::solana_program::{
    program::invoke_signed, stake, stake::state::StakeState, system_program,
};
use anchor_spl::stake::{
    deactivate_stake, withdraw, DeactivateStake, Stake, StakeAccount, Withdraw,
};
#[derive(Accounts)]
pub struct PartialUnstake<'info> {
    #[account(mut)]
    pub state: Box<Account<'info, State>>,
    #[account(
        address = state.validator_system.manager_authority
            @ MarinadeError::InvalidValidatorManager
    )]
    pub validator_manager_authority: Signer<'info>,
    #[account(
        mut,
        address = state.validator_system.validator_list.account,
    )]
    pub validator_list: Account<'info, ValidatorList>,
    #[account(
        mut,
        address = state.stake_system.stake_list.account,
    )]
    pub stake_list: Account<'info, StakeList>,
    #[account(mut)]
    pub stake_account: Box<Account<'info, StakeAccount>>,
    #[account(
        seeds = [
            &state.key().to_bytes(),
            StakeSystem::STAKE_DEPOSIT_SEED
        ],
        bump = state.stake_system.stake_deposit_bump_seed
    )]
    pub stake_deposit_authority: UncheckedAccount<'info>,
    #[account(
        seeds = [
            &state.key().to_bytes(),
            State::RESERVE_SEED
        ],
        bump = state.reserve_bump_seed
    )]
    pub reserve_pda: SystemAccount<'info>,
    #[account(
        init,
        payer = split_stake_rent_payer,
        space = std::mem::size_of::<StakeState>(),
        owner = stake::program::ID,
    )]
    pub split_stake_account: Account<'info, StakeAccount>,
    #[account(
        mut,
        owner = system_program::ID
    )]
    pub split_stake_rent_payer: Signer<'info>,
    pub clock: Sysvar<'info, Clock>,
    pub rent: Sysvar<'info, Rent>,
    pub stake_history: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    pub stake_program: Program<'info, Stake>,
}
impl<'info> PartialUnstake<'info> {
    pub fn process(
        &mut self,
        stake_index: u32,
        validator_index: u32,
        desired_unstake_amount: u64,
    ) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        assert!(
            desired_unstake_amount >= self.state.stake_system.min_stake,
            "desired_unstake_amount too low"
        );
        let mut validator = self.state.validator_system.get(
            &self.validator_list.to_account_info().data.as_ref().borrow(),
            validator_index,
        )?;
        let mut stake = self.state.stake_system.get_checked(
            &self.stake_list.to_account_info().data.as_ref().borrow(),
            stake_index,
            self.stake_account.to_account_info().key,
        )?;
        if stake.is_emergency_unstaking != 0 {
            return err!(MarinadeError::StakeAccountIsEmergencyUnstaking);
        }
        check_stake_amount_and_validator(
            &self.stake_account,
            stake.last_update_delegated_lamports,
            &validator.validator_account,
        )?;
        let total_stake_delta_i128 = self.state.stake_delta(self.reserve_pda.lamports());
        let total_stake_target_i128 =
            self.state.validator_system.total_active_balance as i128 + total_stake_delta_i128;
        let total_stake_target =
            u64::try_from(total_stake_target_i128).expect("total_stake_target+stake_delta");
        let validator_stake_target = self
            .state
            .validator_system
            .validator_stake_target(&validator, total_stake_target)?;
        if validator.active_balance <= validator_stake_target + self.state.stake_system.min_stake {
            msg!(
                "Current validator {} stake {} is <= target {} +min_stake",
                validator.validator_account,
                validator.active_balance,
                validator_stake_target
            );
            self.return_unused_split_stake_account_rent()?;
            return Ok(());
        }
        let max_unstake_from_validator = validator.active_balance - validator_stake_target;
        let unstake_amount = if desired_unstake_amount > max_unstake_from_validator {
            max_unstake_from_validator
        } else {
            desired_unstake_amount
        };
        let stake_account_after = stake
            .last_update_delegated_lamports
            .saturating_sub(unstake_amount);
        let unstaked_from_account = if stake_account_after < self.state.stake_system.min_stake {
            msg!("Deactivate whole stake {}", stake.stake_account);
            deactivate_stake(CpiContext::new_with_signer(
                self.stake_program.to_account_info(),
                DeactivateStake {
                    stake: self.stake_account.to_account_info(),
                    staker: self.stake_deposit_authority.to_account_info(),
                    clock: self.clock.to_account_info(),
                },
                &[&[
                    &self.state.key().to_bytes(),
                    StakeSystem::STAKE_DEPOSIT_SEED,
                    &[self.state.stake_system.stake_deposit_bump_seed],
                ]],
            ))?;
            stake.is_emergency_unstaking = 1;
            self.return_unused_split_stake_account_rent()?;
            stake.last_update_delegated_lamports
        } else {
            msg!(
                "Deactivate split {} ({} lamports) from stake {}",
                self.split_stake_account.key(),
                unstake_amount,
                stake.stake_account
            );
            self.state.stake_system.add(
                &mut self.stake_list.to_account_info().data.as_ref().borrow_mut(),
                &self.split_stake_account.key(),
                unstake_amount,
                &self.clock,
                1,
            )?;
            let split_instruction = stake::instruction::split(
                self.stake_account.to_account_info().key,
                self.stake_deposit_authority.key,
                unstake_amount,
                &self.split_stake_account.key(),
            )
            .last()
            .unwrap()
            .clone();
            invoke_signed(
                &split_instruction,
                &[
                    self.stake_program.to_account_info(),
                    self.stake_account.to_account_info(),
                    self.split_stake_account.to_account_info(),
                    self.stake_deposit_authority.to_account_info(),
                ],
                &[&[
                    &self.state.key().to_bytes(),
                    StakeSystem::STAKE_DEPOSIT_SEED,
                    &[self.state.stake_system.stake_deposit_bump_seed],
                ]],
            )?;
            deactivate_stake(CpiContext::new_with_signer(
                self.stake_program.to_account_info(),
                DeactivateStake {
                    stake: self.split_stake_account.to_account_info(),
                    staker: self.stake_deposit_authority.to_account_info(),
                    clock: self.clock.to_account_info(),
                },
                &[&[
                    &self.state.key().to_bytes(),
                    StakeSystem::STAKE_DEPOSIT_SEED,
                    &[self.state.stake_system.stake_deposit_bump_seed],
                ]],
            ))?;
            stake.last_update_delegated_lamports -= unstake_amount;
            unstake_amount
        };
        self.state
            .on_stake_moved(unstaked_from_account, &self.clock)?;
        validator.active_balance -= unstaked_from_account;
        self.state.validator_system.total_active_balance -= unstaked_from_account;
        self.state.emergency_cooling_down += unstaked_from_account;
        self.state.stake_system.set(
            &mut self.stake_list.to_account_info().data.as_ref().borrow_mut(),
            stake_index,
            stake,
        )?;
        self.state.validator_system.set(
            &mut self
                .validator_list
                .to_account_info()
                .data
                .as_ref()
                .borrow_mut(),
            validator_index,
            validator,
        )?;
        Ok(())
    }
    pub fn return_unused_split_stake_account_rent(&self) -> Result<()> {
        withdraw(
            CpiContext::new(
                self.stake_program.to_account_info(),
                Withdraw {
                    stake: self.split_stake_account.to_account_info(),
                    withdrawer: self.split_stake_account.to_account_info(),
                    to: self.split_stake_rent_payer.to_account_info(),
                    clock: self.clock.to_account_info(),
                    stake_history: self.stake_history.to_account_info(),
                },
            ),
            self.split_stake_account.to_account_info().lamports(),
            None,
        )
    }
}