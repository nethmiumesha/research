use anchor_lang::prelude::*;
use anchor_lang::system_program::{transfer, Transfer};
use crate::events::delayed_unstake::ClaimEvent;
use crate::state::delayed_unstake_ticket::TicketAccountData;
use crate::MarinadeError;
use crate::State;
const WAIT_EPOCHS: u64 = 1;
const EXTRA_WAIT_SECONDS: i64 = 30 * 60;
#[derive(Accounts)]
pub struct Claim<'info> {
    #[account(mut)]
    pub state: Account<'info, State>,
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
        close = transfer_sol_to,
    )]
    pub ticket_account: Account<'info, TicketAccountData>,
    #[account(
        mut,
        address = ticket_account.beneficiary @ MarinadeError::WrongBeneficiary
    )]
    pub transfer_sol_to: SystemAccount<'info>,
    pub clock: Sysvar<'info, Clock>,
    pub system_program: Program<'info, System>,
}
impl<'info> Claim<'info> {
    fn check_ticket_account(&self) -> Result<()> {
        require_keys_eq!(
            self.ticket_account.state_address,
            self.state.key(),
            MarinadeError::InvalidDelayedUnstakeTicket
        );
        require_neq!(
            self.ticket_account.lamports_amount,
            0,
            MarinadeError::ReusingDelayedUnstakeTicket
        );
        require_gte!(
            self.clock.epoch,
            self.ticket_account.created_epoch + WAIT_EPOCHS,
            MarinadeError::TicketNotDue
        );
        if self.ticket_account.created_epoch + WAIT_EPOCHS == self.clock.epoch {
            require_gte!(
                self.clock.unix_timestamp - self.clock.epoch_start_timestamp,
                EXTRA_WAIT_SECONDS,
                MarinadeError::TicketNotReady
            );
        }
        Ok(())
    }
    pub fn process(&mut self) -> Result<()> {
        require!(!self.state.paused, MarinadeError::ProgramIsPaused);
        self.check_ticket_account()
            .map_err(|e| e.with_account_name("ticket_account"))?;
        let user_balance = self.transfer_sol_to.lamports();
        let reserve_balance = self.reserve_pda.lamports();
        let lamports = self.ticket_account.lamports_amount;
        let available_for_claim = reserve_balance - self.state.rent_exempt_for_token_acc;
        if lamports > available_for_claim {
            msg!(
                "Requested to claim {} when only {} ready. Wait a few hours and retry",
                lamports,
                available_for_claim
            );
            return err!(MarinadeError::TicketNotReady);
        }
        let circulating_ticket_balance = self.state.circulating_ticket_balance;
        let circulating_ticket_count = self.state.circulating_ticket_count;
        self.state.circulating_ticket_balance -= lamports;
        self.state.circulating_ticket_count -= 1;
        self.ticket_account.lamports_amount = 0;
        transfer(
            CpiContext::new_with_signer(
                self.system_program.to_account_info(),
                Transfer {
                    from: self.reserve_pda.to_account_info(),
                    to: self.transfer_sol_to.to_account_info(),
                },
                &[&[
                    &self.state.key().to_bytes(),
                    State::RESERVE_SEED,
                    &[self.state.reserve_bump_seed],
                ]],
            ),
            lamports,
        )?;
        self.state.on_transfer_from_reserve(lamports);
        emit!(ClaimEvent {
            state: self.state.key(),
            epoch: self.clock.epoch,
            ticket: self.ticket_account.key(),
            beneficiary: self.ticket_account.beneficiary,
            circulating_ticket_balance,
            circulating_ticket_count,
            reserve_balance,
            user_balance,
            amount: lamports,
        });
        Ok(())
    }
}