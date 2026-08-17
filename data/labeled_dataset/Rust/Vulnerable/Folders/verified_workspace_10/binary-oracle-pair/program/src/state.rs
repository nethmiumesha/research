use {
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::pubkey::Pubkey,
};
pub const UNINITIALIZED_VERSION: u8 = 0;
pub const POOL_VERSION: u8 = 1;
#[repr(C)]
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Pool {
    pub version: u8,
    pub bump_seed: u8,
    pub token_program_id: Pubkey,
    pub deposit_account: Pubkey,
    pub token_pass_mint: Pubkey,
    pub token_fail_mint: Pubkey,
    pub decider: Pubkey,
    pub mint_end_slot: u64,
    pub decide_end_slot: u64,
    pub decision: Decision,
}
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub enum Decision {
    Undecided,
    Pass,
    Fail,
}
impl Pool {
    pub const LEN: usize = 179;
    pub fn is_initialized(&self) -> bool {
        self.version != UNINITIALIZED_VERSION
    }
}
mod test {
}