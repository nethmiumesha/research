use crate::{
    checks::check_stake_amount_and_validator,
    error::MarinadeError,
    events::crank::{RedelegateEvent, SplitStakeAccountInfo},
    state::{
        stake_system::{StakeList, StakeRecord, StakeSystem},
        validator_system::ValidatorList,
    },
    State,
};
use std::{cmp::min, convert::TryFrom};
use anchor_lang::prelude::*;
use anchor_lang::solana_program::{
    program::invoke_signed,
    stake::{self, state::StakeState},
    system_program,
};
use anchor_spl::stake::{withdraw, Stake, StakeAccount, Withdraw};
#[derive(Accounts)]
pub struct ReDelegate<'info> {
    #[account(mut)]
    pub state: Box<Account<'info, State>>,
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
    pub dest_validator_account: UncheckedAccount<'info>,
    #[account(
        init,
        payer = split_stake_rent_payer,
        space = std::mem::size_of::<StakeState>(),
        owner = stake::program::ID,
    )]
    pub redelegate_stake_account: Account<'info, StakeAccount>,
    pub clock: Sysvar<'info, Clock>,
    pub stake_history: UncheckedAccount<'info>,
    pub stake_config: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    pub stake_program: Program<'info, Stake>,
}
impl<'info> ReDelegate<'info> {
    pub fn process(
        &mut self,
        stake_index: u32,
        source_validator_index: u32,
        dest_validator_index: u32,
    ) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        require_neq!(
            source_validator_index,
            dest_validator_index,
            MarinadeError::SourceAndDestValidatorsAreTheSame
        );
        {
            let last_slot = EpochSchedule::get()
                .unwrap()
                .get_last_slot_in_epoch(self.clock.epoch);
            require_gte!(
                self.clock.slot,
                last_slot.saturating_sub(self.state.stake_system.slots_for_stake_delta),
                MarinadeError::TooEarlyForStakeDelta
            );
        }
        let mut stake = self.state.stake_system.get_checked(
            &self.stake_list.to_account_info().data.as_ref().borrow(),
            stake_index,
            self.stake_account.to_account_info().key,
        )?;
        let last_update_delegation = stake.last_update_delegated_lamports;
        require_eq!(
            stake.is_emergency_unstaking,
            0,
            MarinadeError::StakeAccountIsEmergencyUnstaking
        );
        let mut source_validator = self.state.validator_system.get(
            &self.validator_list.to_account_info().data.as_ref().borrow(),
            source_validator_index,
        )?;
        let source_validator_balance = source_validator.active_balance;
        check_stake_amount_and_validator(
            &self.stake_account,
            stake.last_update_delegated_lamports,
            &source_validator.validator_account,
        )?;
        let total_stake_delta_i128 = self.state.stake_delta(self.reserve_pda.lamports());
        let total_stake_target_i128 =
            self.state.validator_system.total_active_balance as i128 + total_stake_delta_i128;
        let total_stake_target =
            u64::try_from(total_stake_target_i128).expect("total_stake_target+stake_delta");
        let source_validator_stake_target = self
            .state
            .validator_system
            .validator_stake_target(&source_validator, total_stake_target)?;
        if source_validator.active_balance
            < source_validator_stake_target + self.state.stake_system.min_stake
        {
            msg!(
                "Source validator {} stake {} is <= target {} +min_stake",
                source_validator.validator_account,
                source_validator.active_balance,
                source_validator_stake_target
            );
            self.return_rent_unused_stake_account(self.split_stake_account.to_account_info())?;
            self.return_rent_unused_stake_account(self.redelegate_stake_account.to_account_info())?;
            return Ok(());
        }
        let max_redelegate_from_source_account = min(
            source_validator.active_balance - source_validator_stake_target,
            stake.last_update_delegated_lamports,
        );
        let mut dest_validator = self
            .state
            .validator_system
            .get_checked(
                &self.validator_list.to_account_info().data.as_ref().borrow(),
                dest_validator_index,
                &self.dest_validator_account.key(),
            )
            .map_err(|e| e.with_account_name("dest_validator_account"))?;
        let dest_validator_balance = dest_validator.active_balance;
        let dest_validator_stake_target = self
            .state
            .validator_system
            .validator_stake_target(&dest_validator, total_stake_target)?;
        if dest_validator.active_balance + self.state.stake_system.min_stake
            > dest_validator_stake_target
        {
            msg!(
                "Dest validator {} stake+min_stake {} is > target {}",
                dest_validator.validator_account,
                dest_validator.active_balance,
                dest_validator_stake_target
            );
            self.return_rent_unused_stake_account(self.split_stake_account.to_account_info())?;
            self.return_rent_unused_stake_account(self.redelegate_stake_account.to_account_info())?;
            return Ok(());
        }
        let max_space_dest_validator = dest_validator_stake_target - dest_validator.active_balance;
        let redelegate_amount_theoretical =
            min(max_space_dest_validator, max_redelegate_from_source_account);
        let stake_account_after =
            stake.last_update_delegated_lamports - redelegate_amount_theoretical;
        let (source_account, redelegate_amount_effective) =
            if stake_account_after < self.state.stake_system.min_stake {
                msg!("ReDelegate whole stake {}", stake.stake_account);
                self.return_rent_unused_stake_account(self.split_stake_account.to_account_info())?;
                stake.is_emergency_unstaking = 0;
                let amount_to_redelegate_whole_account = stake.last_update_delegated_lamports;
                stake.last_update_delegated_lamports = 0;
                (
                    self.stake_account.to_account_info(),
                    amount_to_redelegate_whole_account,
                )
            } else {
                self.split_stake_for_redelegation(&mut stake, redelegate_amount_theoretical)?;
                (
                    self.split_stake_account.to_account_info(),
                    redelegate_amount_theoretical,
                )
            };
        self.state
            .on_stake_moved(redelegate_amount_effective, &self.clock)?;
        let redelegate_instruction = &stake::instruction::redelegate(
            &source_account.key(),
            &self.stake_deposit_authority.key(),
            &self.dest_validator_account.key(),
            &self.redelegate_stake_account.key(),
        )
        .last()
        .unwrap()
        .clone();
        invoke_signed(
            redelegate_instruction,
            &[
                source_account.clone(),
                self.dest_validator_account.to_account_info(),
                self.redelegate_stake_account.to_account_info(),
                self.stake_config.to_account_info(),
                self.stake_deposit_authority.to_account_info(),
            ],
            &[&[
                &self.state.key().to_bytes(),
                StakeSystem::STAKE_DEPOSIT_SEED,
                &[self.state.stake_system.stake_deposit_bump_seed],
            ]],
        )?;
        self.state.stake_system.add(
            &mut self.stake_list.to_account_info().data.as_ref().borrow_mut(),
            &self.redelegate_stake_account.key(),
            redelegate_amount_effective,
            &self.clock,
            0,
        )?;
        source_validator.active_balance -= redelegate_amount_effective;
        dest_validator.active_balance += redelegate_amount_effective;
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
            source_validator_index,
            source_validator,
        )?;
        self.state.validator_system.set(
            &mut self
                .validator_list
                .to_account_info()
                .data
                .as_ref()
                .borrow_mut(),
            dest_validator_index,
            dest_validator,
        )?;
        emit!(RedelegateEvent {
            state: self.state.key(),
            epoch: self.clock.epoch,
            stake_index,
            stake_account: self.stake_account.key(),
            last_update_delegation,
            source_validator_index,
            source_validator_vote: source_validator.validator_account,
            source_validator_score: source_validator.score,
            source_validator_balance,
            source_validator_stake_target,
            dest_validator_index,
            dest_validator_vote: dest_validator.validator_account,
            dest_validator_score: dest_validator.score,
            dest_validator_balance,
            dest_validator_stake_target,
            redelegate_amount: redelegate_amount_effective,
            split_stake_account: if source_account.key() == self.split_stake_account.key() {
                Some(SplitStakeAccountInfo {
                    account: self.split_stake_account.key(),
                    index: self.state.stake_system.stake_count() - 2,
                })
            } else {
                None
            },
            redelegate_stake_index: self.state.stake_system.stake_count() - 1,
            redelegate_stake_account: self.redelegate_stake_account.key(),
        });
        Ok(())
    }
    pub fn return_rent_unused_stake_account(
        &self,
        unused_stake_account: AccountInfo<'info>,
    ) -> Result<()> {
        withdraw(
            CpiContext::new(
                self.stake_program.to_account_info(),
                Withdraw {
                    stake: unused_stake_account.clone(),
                    withdrawer: unused_stake_account.clone(),
                    to: self.split_stake_rent_payer.to_account_info(),
                    clock: self.clock.to_account_info(),
                    stake_history: self.stake_history.to_account_info(),
                },
            ),
            unused_stake_account.lamports(),
            None,
        )
    }
    #[inline]
    pub fn split_stake_for_redelegation(
        &mut self,
        stake: &mut StakeRecord,
        amount: u64,
    ) -> Result<()> {
        msg!(
            "Split {} lamports from stake {} to {}",
            amount,
            stake.stake_account,
            self.split_stake_account.key(),
        );
        self.state.stake_system.add(
            &mut self.stake_list.to_account_info().data.as_ref().borrow_mut(),
            &self.split_stake_account.key(),
            0,
            &self.clock,
            0,
        )?;
        let split_instruction = stake::instruction::split(
            self.stake_account.to_account_info().key,
            &self.stake_deposit_authority.key(),
            amount,
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
        stake.last_update_delegated_lamports -= amount;
        Ok(())
    }
}