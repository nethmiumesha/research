use anchor_lang::prelude::*;
#[account]
#[derive(Debug)]
pub struct TicketAccountData {
    pub state_address: Pubkey,
    pub beneficiary: Pubkey,
    pub lamports_amount: u64,
    pub created_epoch: u64,
}