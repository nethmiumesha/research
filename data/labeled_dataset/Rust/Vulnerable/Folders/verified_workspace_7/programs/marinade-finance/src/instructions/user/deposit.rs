use anchor_lang::prelude::*;
use anchor_lang::solana_program::system_program;
use anchor_lang::system_program::{transfer, Transfer};
use anchor_spl::token::{
    mint_to, transfer as transfer_tokens, Mint, MintTo, Token, TokenAccount,
    Transfer as TransferTokens,
};
use crate::error::MarinadeError;
use crate::events::user::DepositEvent;
use crate::state::liq_pool::LiqPool;
use crate::{require_lte, State};
#[derive(Accounts)]
pub struct Deposit<'info> {
    #[account(
        mut,
        has_one = msol_mint
    )]
    pub state: Box<Account<'info, State>>,
    #[account(mut)]
    pub msol_mint: Box<Account<'info, Mint>>,
    #[account(
        mut,
        seeds = [
            &state.key().to_bytes(),
            LiqPool::SOL_LEG_SEED
        ],
        bump = state.liq_pool.sol_leg_bump_seed
    )]
    pub liq_pool_sol_leg_pda: SystemAccount<'info>,
    #[account(
        mut,
        address = state.liq_pool.msol_leg
    )]
    pub liq_pool_msol_leg: Box<Account<'info, TokenAccount>>,
    #[account(
        seeds = [
            &state.key().to_bytes(),
            LiqPool::MSOL_LEG_AUTHORITY_SEED
        ],
        bump = state.liq_pool.msol_leg_authority_bump_seed
    )]
    pub liq_pool_msol_leg_authority: UncheckedAccount<'info>,
    #[account(
        mut,
        seeds = [
            &state.key().to_bytes(),
            State::RESERVE_SEED
        ],
        bump = state.reserve_bump_seed
    )]
    pub reserve_pda: SystemAccount<'info>,
    #[account(
        mut,
        owner = system_program::ID
    )]
    pub transfer_from: Signer<'info>,
    #[account(
        mut,
        token::mint = state.msol_mint
    )]
    pub mint_to: Box<Account<'info, TokenAccount>>,
    #[account(
        seeds = [
            &state.key().to_bytes(),
            State::MSOL_MINT_AUTHORITY_SEED
        ],
        bump = state.msol_mint_authority_bump_seed
    )]
    pub msol_mint_authority: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    pub token_program: Program<'info, Token>,
}
impl<'info> Deposit<'info> {
    pub fn process(&mut self, lamports: u64) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        require_gte!(
            lamports,
            self.state.min_deposit,
            MarinadeError::DepositAmountIsTooLow
        );
        let user_sol_balance = self.transfer_from.lamports();
        require_gte!(
            user_sol_balance,
            lamports,
            MarinadeError::NotEnoughUserFunds
        );
        let user_msol_balance = self.mint_to.amount;
        let reserve_balance = self.reserve_pda.lamports();
        let sol_leg_balance = self.liq_pool_sol_leg_pda.lamports();
        require_lte!(
            self.msol_mint.supply,
            self.state.msol_supply,
            MarinadeError::UnregisteredMsolMinted
        );
        let total_virtual_staked_lamports = self.state.total_virtual_staked_lamports();
        let msol_supply = self.state.msol_supply;
        let user_msol_buy_order = self.state.calc_msol_from_lamports(lamports)?;
        msg!("--- user_m_sol_buy_order {}", user_msol_buy_order);
        let msol_leg_balance = self.liq_pool_msol_leg.amount;
        let msol_swapped: u64 = user_msol_buy_order.min(msol_leg_balance);
        msg!("--- swap_m_sol_max {}", msol_swapped);
        let sol_swapped = if msol_swapped > 0 {
            let sol_swapped = if user_msol_buy_order == msol_swapped {
                lamports
            } else {
                self.state.msol_to_sol(msol_swapped)?
            };
            transfer_tokens(
                CpiContext::new_with_signer(
                    self.token_program.to_account_info(),
                    TransferTokens {
                        from: self.liq_pool_msol_leg.to_account_info(),
                        to: self.mint_to.to_account_info(),
                        authority: self.liq_pool_msol_leg_authority.to_account_info(),
                    },
                    &[&[
                        &self.state.key().to_bytes(),
                        LiqPool::MSOL_LEG_AUTHORITY_SEED,
                        &[self.state.liq_pool.msol_leg_authority_bump_seed],
                    ]],
                ),
                msol_swapped,
            )?;
            transfer(
                CpiContext::new(
                    self.system_program.to_account_info(),
                    Transfer {
                        from: self.transfer_from.to_account_info(),
                        to: self.liq_pool_sol_leg_pda.to_account_info(),
                    },
                ),
                sol_swapped,
            )?;
            sol_swapped
        } else {
            0
        };
        let sol_deposited = lamports - sol_swapped;
        if sol_deposited > 0 {
            self.state.check_staking_cap(sol_deposited)?;
            transfer(
                CpiContext::new(
                    self.system_program.to_account_info(),
                    Transfer {
                        from: self.transfer_from.to_account_info(),
                        to: self.reserve_pda.to_account_info(),
                    },
                ),
                sol_deposited,
            )?;
            self.state.on_transfer_to_reserve(sol_deposited);
        }
        let msol_minted = user_msol_buy_order - msol_swapped;
        if msol_minted > 0 {
            msg!("--- msol_to_mint {}", msol_minted);
            mint_to(
                CpiContext::new_with_signer(
                    self.token_program.to_account_info(),
                    MintTo {
                        mint: self.msol_mint.to_account_info(),
                        to: self.mint_to.to_account_info(),
                        authority: self.msol_mint_authority.to_account_info(),
                    },
                    &[&[
                        &self.state.key().to_bytes(),
                        State::MSOL_MINT_AUTHORITY_SEED,
                        &[self.state.msol_mint_authority_bump_seed],
                    ]],
                ),
                msol_minted,
            )?;
            self.state.on_msol_mint(msol_minted);
        }
        emit!(DepositEvent {
            state: self.state.key(),
            sol_owner: self.transfer_from.key(),
            user_sol_balance,
            user_msol_balance,
            sol_leg_balance,
            msol_leg_balance,
            reserve_balance,
            sol_swapped,
            msol_swapped,
            sol_deposited,
            msol_minted,
            total_virtual_staked_lamports,
            msol_supply
        });
        Ok(())
    }
}