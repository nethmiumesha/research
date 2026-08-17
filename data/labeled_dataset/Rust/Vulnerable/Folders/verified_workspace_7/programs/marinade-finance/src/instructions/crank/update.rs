use std::ops::{Deref, DerefMut};
use anchor_lang::prelude::*;
use anchor_lang::solana_program::sysvar::stake_history;
use anchor_lang::system_program::{transfer, Transfer};
use anchor_spl::stake::{withdraw, Stake, StakeAccount, Withdraw};
use anchor_spl::token::{mint_to, Mint, MintTo, Token};
use crate::events::crank::{UpdateActiveEvent, UpdateDeactivatedEvent};
use crate::events::U64ValueChange;
use crate::state::stake_system::StakeList;
use crate::state::validator_system::ValidatorList;
use crate::{
    error::MarinadeError,
    state::stake_system::{StakeRecord, StakeSystem},
    State,
};
#[derive(Accounts)]
pub struct UpdateCommon<'info> {
    #[account(
        mut,
        has_one = treasury_msol_account,
        has_one = msol_mint
    )]
    pub state: Box<Account<'info, State>>,
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
            StakeSystem::STAKE_WITHDRAW_SEED
        ],
        bump = state.stake_system.stake_withdraw_bump_seed
    )]
    pub stake_withdraw_authority: UncheckedAccount<'info>,
    #[account(
        mut,
        seeds = [
            &state.key().to_bytes(),
            State::RESERVE_SEED
        ],
        bump = state.reserve_bump_seed
    )]
    pub reserve_pda: SystemAccount<'info>,
    #[account(mut)]
    pub msol_mint: Box<Account<'info, Mint>>,
    #[account(
        seeds = [
            &state.key().to_bytes(),
            State::MSOL_MINT_AUTHORITY_SEED
        ],
        bump = state.msol_mint_authority_bump_seed
    )]
    pub msol_mint_authority: UncheckedAccount<'info>,
    #[account(mut)]
    pub treasury_msol_account: UncheckedAccount<'info>,
    pub clock: Sysvar<'info, Clock>,
    #[account(address = stake_history::ID)]
    pub stake_history: UncheckedAccount<'info>,
    pub stake_program: Program<'info, Stake>,
    pub token_program: Program<'info, Token>,
}
#[derive(Accounts)]
pub struct UpdateActive<'info> {
    pub common: UpdateCommon<'info>,
    #[account(
        mut,
        address = common.state.validator_system.validator_list.account,
    )]
    pub validator_list: Account<'info, ValidatorList>,
}
impl<'info> Deref for UpdateActive<'info> {
    type Target = UpdateCommon<'info>;
    fn deref(&self) -> &Self::Target {
        &self.common
    }
}
impl<'info> DerefMut for UpdateActive<'info> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.common
    }
}
#[derive(Accounts)]
pub struct UpdateDeactivated<'info> {
    pub common: UpdateCommon<'info>,
    #[account(
        mut,
        address = common.state.operational_sol_account
    )]
    pub operational_sol_account: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}
impl<'info> Deref for UpdateDeactivated<'info> {
    type Target = UpdateCommon<'info>;
    fn deref(&self) -> &Self::Target {
        &self.common
    }
}
impl<'info> DerefMut for UpdateDeactivated<'info> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.common
    }
}
struct BeginOutput {
    stake: StakeRecord,
    is_treasury_msol_ready_for_transfer: bool,
}
impl<'info> UpdateCommon<'info> {
    fn begin(&mut self, stake_index: u32) -> Result<BeginOutput> {
        let is_treasury_msol_ready_for_transfer = self
            .state
            .get_treasury_msol_balance(&self.treasury_msol_account)
            .is_some();
        let virtual_reserve_balance =
            self.state.available_reserve_balance + self.state.rent_exempt_for_token_acc;
        if self.reserve_pda.lamports() < virtual_reserve_balance {
            msg!(
                "Warning: Reserve must have {} lamports but got {}",
                virtual_reserve_balance,
                self.reserve_pda.lamports()
            );
        }
        self.state.available_reserve_balance = self
            .reserve_pda
            .lamports()
            .saturating_sub(self.state.rent_exempt_for_token_acc);
        if self.msol_mint.supply > self.state.msol_supply {
            msg!(
                "Warning: mSOL minted {} lamports outside of marinade",
                self.msol_mint.supply - self.state.msol_supply
            );
            self.state.staking_sol_cap = 0;
        }
        self.state.msol_supply = self.msol_mint.supply;
        let stake = self.state.stake_system.get_checked(
            &self.stake_list.to_account_info().data.as_ref().borrow(),
            stake_index,
            self.stake_account.to_account_info().key,
        )?;
        Ok(BeginOutput {
            stake,
            is_treasury_msol_ready_for_transfer,
        })
    }
    pub fn withdraw_to_reserve(&mut self, amount: u64) -> Result<()> {
        if amount > 0 {
            withdraw(
                CpiContext::new_with_signer(
                    self.stake_program.to_account_info(),
                    Withdraw {
                        stake: self.stake_account.to_account_info(),
                        withdrawer: self.stake_withdraw_authority.to_account_info(),
                        to: self.reserve_pda.to_account_info(),
                        clock: self.clock.to_account_info(),
                        stake_history: self.stake_history.to_account_info(),
                    },
                    &[&[
                        &self.state.key().to_bytes(),
                        StakeSystem::STAKE_WITHDRAW_SEED,
                        &[self.state.stake_system.stake_withdraw_bump_seed],
                    ]],
                ),
                amount,
                None,
            )?;
            self.state.on_transfer_to_reserve(amount);
        }
        Ok(())
    }
    pub fn mint_to_treasury(&mut self, msol_lamports: u64) -> Result<()> {
        if msol_lamports > 0 {
            mint_to(
                CpiContext::new_with_signer(
                    self.token_program.to_account_info(),
                    MintTo {
                        mint: self.msol_mint.to_account_info(),
                        to: self.treasury_msol_account.to_account_info(),
                        authority: self.msol_mint_authority.to_account_info(),
                    },
                    &[&[
                        &self.state.key().to_bytes(),
                        State::MSOL_MINT_AUTHORITY_SEED,
                        &[self.state.msol_mint_authority_bump_seed],
                    ]],
                ),
                msol_lamports,
            )?;
            self.state.on_msol_mint(msol_lamports);
        }
        Ok(())
    }
    #[inline]
    pub fn update_msol_price(&mut self) -> Result<U64ValueChange> {
        let old = self.state.msol_price;
        self.state.msol_price = self.state.msol_to_sol(State::PRICE_DENOMINATOR)?;
        Ok(U64ValueChange {
            old,
            new: self.state.msol_price,
        })
    }
    pub fn mint_protocol_fees(&mut self, lamports_incoming: u64) -> Result<u64> {
        let protocol_rewards_fee = self.state.reward_fee.apply(lamports_incoming);
        msg!("protocol_rewards_fee {}", protocol_rewards_fee);
        let fee_as_msol_amount = self.state.calc_msol_from_lamports(protocol_rewards_fee)?;
        self.mint_to_treasury(fee_as_msol_amount)?;
        Ok(fee_as_msol_amount)
    }
}
impl<'info> UpdateActive<'info> {
    pub fn process(&mut self, stake_index: u32, validator_index: u32) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        let total_virtual_staked_lamports = self.state.total_virtual_staked_lamports();
        let msol_supply = self.state.msol_supply;
        let BeginOutput {
            mut stake,
            is_treasury_msol_ready_for_transfer,
        } = self.begin(stake_index)?;
        let delegation = self.stake_account.delegation().ok_or_else(|| {
            error!(MarinadeError::RequiredDelegatedStake).with_account_name("stake_account")
        })?;
        let mut validator = self.state.validator_system.get_checked(
            &self.validator_list.to_account_info().data.as_ref().borrow(),
            validator_index,
            &delegation.voter_pubkey,
        )?;
        let validator_active_balance = validator.active_balance;
        let total_active_balance = self.state.validator_system.total_active_balance;
        require_eq!(
            delegation.deactivation_epoch,
            std::u64::MAX,
            MarinadeError::RequiredActiveStake
        );
        let delegated_lamports = delegation.stake;
        let stake_balance_without_rent = self.stake_account.to_account_info().lamports()
            - self.stake_account.meta().unwrap().rent_exempt_reserve;
        let extra_lamports = stake_balance_without_rent.saturating_sub(delegated_lamports);
        msg!("Extra lamports in stake balance: {}", extra_lamports);
        let extra_msol_fees = if extra_lamports > 0 {
            self.withdraw_to_reserve(extra_lamports)?;
            if is_treasury_msol_ready_for_transfer {
                Some(self.mint_protocol_fees(extra_lamports)?)
            } else {
                None
            }
        } else {
            if is_treasury_msol_ready_for_transfer {
                Some(0)
            } else {
                None
            }
        };
        msg!("current staked lamports {}", delegated_lamports);
        let delegation_growth_msol_fees =
            if delegated_lamports >= stake.last_update_delegated_lamports {
                let rewards = delegated_lamports - stake.last_update_delegated_lamports;
                msg!("Staking rewards: {}", rewards);
                let delegation_growth_msol_fees = if is_treasury_msol_ready_for_transfer {
                    Some(self.mint_protocol_fees(rewards)?)
                } else {
                    None
                };
                validator.active_balance += rewards;
                self.state.validator_system.total_active_balance += rewards;
                delegation_growth_msol_fees
            } else {
                let slashed = stake.last_update_delegated_lamports - delegated_lamports;
                msg!("slashed {}", slashed);
                validator.active_balance = validator.active_balance.saturating_sub(slashed);
                self.state.validator_system.total_active_balance =
                    total_active_balance.saturating_sub(slashed);
                if is_treasury_msol_ready_for_transfer {
                    Some(0)
                } else {
                    None
                }
            };
        stake.last_update_epoch = self.clock.epoch;
        let delegation_change = {
            let old = stake.last_update_delegated_lamports;
            stake.last_update_delegated_lamports = delegated_lamports;
            U64ValueChange {
                old,
                new: delegated_lamports,
            }
        };
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
        let msol_price_change = self.update_msol_price()?;
        self.state.stake_system.set(
            &mut self.stake_list.to_account_info().data.as_ref().borrow_mut(),
            stake_index,
            stake,
        )?;
        assert_eq!(
            self.state.available_reserve_balance + self.state.rent_exempt_for_token_acc,
            self.reserve_pda.lamports()
        );
        emit!(UpdateActiveEvent {
            state: self.state.key(),
            epoch: self.clock.epoch,
            stake_index,
            stake_account: stake.stake_account,
            validator_index,
            validator_vote: validator.validator_account,
            delegation_change,
            delegation_growth_msol_fees,
            extra_lamports,
            extra_msol_fees,
            validator_active_balance,
            total_active_balance,
            msol_price_change,
            reward_fee_used: self.state.reward_fee,
            total_virtual_staked_lamports,
            msol_supply,
        });
        Ok(())
    }
}
impl<'info> UpdateDeactivated<'info> {
    pub fn process(&mut self, stake_index: u32) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        let total_virtual_staked_lamports = self.state.total_virtual_staked_lamports();
        let msol_supply = self.state.msol_supply;
        let operational_sol_balance = self.operational_sol_account.lamports();
        let BeginOutput {
            stake,
            is_treasury_msol_ready_for_transfer,
        } = self.begin(stake_index)?;
        let delegation = self.stake_account.delegation().ok_or_else(|| {
            error!(MarinadeError::RequiredDelegatedStake).with_account_name("stake_account")
        })?;
        require_neq!(
            delegation.deactivation_epoch,
            std::u64::MAX,
            MarinadeError::RequiredDeactivatingStake
        );
        let rent = self.stake_account.meta().unwrap().rent_exempt_reserve;
        let stake_balance_without_rent = self.stake_account.to_account_info().lamports() - rent;
        let msol_fees = if stake_balance_without_rent >= stake.last_update_delegated_lamports {
            let rewards = stake_balance_without_rent - stake.last_update_delegated_lamports;
            msg!("Staking rewards: {}", rewards);
            if is_treasury_msol_ready_for_transfer {
                Some(self.mint_protocol_fees(rewards)?)
            } else {
                None
            }
        } else {
            let slashed = stake.last_update_delegated_lamports - stake_balance_without_rent;
            msg!("Slashed {}", slashed);
            if is_treasury_msol_ready_for_transfer {
                Some(0)
            } else {
                None
            }
        };
        self.common
            .withdraw_to_reserve(self.stake_account.to_account_info().lamports())?;
        transfer(
            CpiContext::new_with_signer(
                self.system_program.to_account_info(),
                Transfer {
                    from: self.reserve_pda.to_account_info(),
                    to: self.operational_sol_account.to_account_info(),
                },
                &[&[
                    &self.state.key().to_bytes(),
                    State::RESERVE_SEED,
                    &[self.state.reserve_bump_seed],
                ]],
            ),
            rent,
        )?;
        self.state.on_transfer_from_reserve(rent);
        if stake.last_update_delegated_lamports != 0 {
            if stake.is_emergency_unstaking == 0 {
                self.state.stake_system.delayed_unstake_cooling_down -=
                    stake.last_update_delegated_lamports;
            } else {
                self.state.emergency_cooling_down -= stake.last_update_delegated_lamports;
            }
        }
        let msol_price_change = self.update_msol_price()?;
        self.common.state.stake_system.remove(
            &mut self
                .common
                .stake_list
                .to_account_info()
                .data
                .as_ref()
                .borrow_mut(),
            stake_index,
        )?;
        emit!(UpdateDeactivatedEvent {
            state: self.state.key(),
            epoch: self.clock.epoch,
            stake_index,
            stake_account: stake.stake_account,
            balance_without_rent_exempt: stake_balance_without_rent,
            last_update_delegated_lamports: stake.last_update_delegated_lamports,
            msol_fees,
            msol_price_change,
            reward_fee_used: self.state.reward_fee,
            operational_sol_balance,
            total_virtual_staked_lamports,
            msol_supply,
        });
        Ok(())
    }
}