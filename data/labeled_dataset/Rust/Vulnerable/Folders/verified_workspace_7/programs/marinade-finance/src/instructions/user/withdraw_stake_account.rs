use crate::{
    checks::check_token_source_account,
    error::MarinadeError,
    events::user::WithdrawStakeAccountEvent,
    state::{
        stake_system::{StakeList, StakeSystem},
        validator_system::ValidatorList,
    },
    State,
};
use anchor_lang::{
    prelude::*,
    solana_program::{
        program::invoke_signed,
        stake,
        stake::state::{StakeAuthorize, StakeState},
        system_program,
    },
};
use anchor_spl::{
    stake::{Stake, StakeAccount},
    token::{burn, transfer, Burn, Mint, Token, TokenAccount, Transfer},
};
use crate::checks::check_stake_amount_and_validator;
#[derive(Accounts)]
pub struct WithdrawStakeAccount<'info> {
    #[account(
        mut,
        has_one = msol_mint,
        has_one = treasury_msol_account,
    )]
    pub state: Box<Account<'info, State>>,
    #[account(mut)]
    pub msol_mint: Box<Account<'info, Mint>>,
    #[account(
        mut,
        token::mint = msol_mint
    )]
    pub burn_msol_from: Box<Account<'info, TokenAccount>>,
    #[account(mut)]
    pub burn_msol_authority: Signer<'info>,
    #[account(mut)]
    pub treasury_msol_account: UncheckedAccount<'info>,
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
    #[account(
        seeds = [
            &state.key().to_bytes(),
            StakeSystem::STAKE_WITHDRAW_SEED
        ],
        bump = state.stake_system.stake_withdraw_bump_seed
    )]
    pub stake_withdraw_authority: UncheckedAccount<'info>,
    #[account(
        seeds = [
            &state.key().to_bytes(),
            StakeSystem::STAKE_DEPOSIT_SEED
        ],
        bump = state.stake_system.stake_deposit_bump_seed
    )]
    pub stake_deposit_authority: UncheckedAccount<'info>,
    #[account(mut)]
    pub stake_account: Box<Account<'info, StakeAccount>>,
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
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
    pub stake_program: Program<'info, Stake>,
}
impl<'info> WithdrawStakeAccount<'info> {
    pub fn process(
        &mut self,
        stake_index: u32,
        validator_index: u32,
        msol_amount: u64,
        beneficiary: Pubkey,
    ) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        require!(
            self.state.withdraw_stake_account_enabled,
            MarinadeError::WithdrawStakeAccountIsNotEnabled
        );
        let user_msol_balance = self.burn_msol_from.amount;
        let total_virtual_staked_lamports = self.state.total_virtual_staked_lamports();
        let msol_supply = self.state.msol_supply;
        check_token_source_account(
            &self.burn_msol_from,
            self.burn_msol_authority.key,
            msol_amount,
        )
        .map_err(|e| e.with_account_name("burn_msol_from"))?;
        let mut stake = self.state.stake_system.get_checked(
            &self.stake_list.to_account_info().data.as_ref().borrow(),
            stake_index,
            self.stake_account.to_account_info().key,
        )?;
        let last_update_stake_delegation = stake.last_update_delegated_lamports;
        require_eq!(
            stake.is_emergency_unstaking,
            0,
            MarinadeError::StakeAccountIsEmergencyUnstaking
        );
        let delegation = self.stake_account.delegation().ok_or_else(|| {
            error!(MarinadeError::RequiredDelegatedStake).with_account_name("stake_account")
        })?;
        require_eq!(
            delegation.deactivation_epoch,
            std::u64::MAX,
            MarinadeError::RequiredActiveStake
        );
        let mut validator = self.state.validator_system.get(
            &self.validator_list.to_account_info().data.as_ref().borrow(),
            validator_index,
        )?;
        check_stake_amount_and_validator(
            &self.stake_account,
            stake.last_update_delegated_lamports,
            &validator.validator_account,
        )?;
        let split_lamports = {
            let sol_value = self.state.msol_to_sol(msol_amount)?;
            require_gte!(
                sol_value,
                self.state.min_withdraw,
                MarinadeError::WithdrawAmountIsTooLow
            );
            let withdraw_stake_account_fee_lamports =
                self.state.withdraw_stake_account_fee.apply(sol_value);
            sol_value - withdraw_stake_account_fee_lamports
        };
        require_gte!(
            split_lamports,
            self.state.stake_system.min_stake,
            MarinadeError::WithdrawStakeLamportsIsTooLow
        );
        require_gte!(
            stake.last_update_delegated_lamports,
            split_lamports,
            MarinadeError::SelectedStakeAccountHasNotEnoughFunds
        );
        require_gte!(
            stake.last_update_delegated_lamports - split_lamports,
            self.state.stake_system.min_stake,
            MarinadeError::StakeAccountRemainderTooLow
        );
        let treasury_msol_balance = self
            .state
            .get_treasury_msol_balance(&self.treasury_msol_account);
        let msol_fees = if treasury_msol_balance.is_some() {
            msol_amount.saturating_sub(self.state.calc_msol_from_lamports(split_lamports)?)
        } else {
            0
        };
        let msol_burned = msol_amount - msol_fees;
        if msol_fees > 0 {
            transfer(
                CpiContext::new(
                    self.token_program.to_account_info(),
                    Transfer {
                        from: self.burn_msol_from.to_account_info(),
                        to: self.treasury_msol_account.to_account_info(),
                        authority: self.burn_msol_authority.to_account_info(),
                    },
                ),
                msol_fees,
            )?;
        }
        if msol_burned > 0 {
            burn(
                CpiContext::new(
                    self.token_program.to_account_info(),
                    Burn {
                        mint: self.msol_mint.to_account_info(),
                        from: self.burn_msol_from.to_account_info(),
                        authority: self.burn_msol_authority.to_account_info(),
                    },
                ),
                msol_burned,
            )?;
            self.state.on_msol_burn(msol_burned);
        }
        msg!(
            "Split {} lamports from stake {} into {}",
            split_lamports,
            stake.stake_account,
            self.split_stake_account.key(),
        );
        let split_instruction = stake::instruction::split(
            self.stake_account.to_account_info().key,
            self.stake_deposit_authority.key,
            split_lamports,
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
        stake.last_update_delegated_lamports -= split_lamports;
        validator.active_balance -= split_lamports;
        self.state.validator_system.total_active_balance -= split_lamports;
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
        invoke_signed(
            &stake::instruction::authorize(
                self.split_stake_account.to_account_info().key,
                self.stake_withdraw_authority.key,
                &beneficiary,
                StakeAuthorize::Staker,
                None,
            ),
            &[
                self.split_stake_account.to_account_info(),
                self.stake_withdraw_authority.to_account_info(),
                self.stake_program.to_account_info(),
                self.clock.to_account_info(),
            ],
            &[&[
                &self.state.key().to_bytes(),
                StakeSystem::STAKE_WITHDRAW_SEED,
                &[self.state.stake_system.stake_withdraw_bump_seed],
            ]],
        )?;
        invoke_signed(
            &stake::instruction::authorize(
                self.split_stake_account.to_account_info().key,
                self.stake_withdraw_authority.key,
                &beneficiary,
                StakeAuthorize::Withdrawer,
                None,
            ),
            &[
                self.split_stake_account.to_account_info(),
                self.stake_withdraw_authority.to_account_info(),
                self.stake_program.to_account_info(),
                self.clock.to_account_info(),
            ],
            &[&[
                &self.state.key().to_bytes(),
                StakeSystem::STAKE_WITHDRAW_SEED,
                &[self.state.stake_system.stake_withdraw_bump_seed],
            ]],
        )?;
        emit!(WithdrawStakeAccountEvent {
            state: self.state.key(),
            epoch: self.clock.epoch,
            stake_index,
            stake: self.stake_account.key(),
            last_update_stake_delegation,
            validator_index,
            validator: validator.validator_account,
            user_msol_auth: self.burn_msol_authority.key(),
            beneficiary,
            user_msol_balance,
            msol_burned,
            msol_fees,
            split_stake: self.split_stake_account.key(),
            split_lamports,
            fee_bp_cents: self.state.withdraw_stake_account_fee.bp_cents,
            total_virtual_staked_lamports,
            msol_supply,
        });
        Ok(())
    }
}