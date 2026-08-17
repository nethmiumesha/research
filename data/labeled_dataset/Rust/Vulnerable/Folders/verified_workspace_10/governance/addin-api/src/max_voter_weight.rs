use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{clock::Slot, program_pack::IsInitialized, pubkey::Pubkey},
    spl_governance_tools::account::AccountMaxSize,
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct MaxVoterWeightRecord {
    pub account_discriminator: [u8; 8],
    pub realm: Pubkey,
    pub governing_token_mint: Pubkey,
    pub max_voter_weight: u64,
    pub max_voter_weight_expiry: Option<Slot>,
    pub reserved: [u8; 8],
}
impl AccountMaxSize for MaxVoterWeightRecord {}
impl MaxVoterWeightRecord {
    pub const ACCOUNT_DISCRIMINATOR: [u8; 8] = [157, 95, 242, 151, 16, 98, 26, 118];
}
impl IsInitialized for MaxVoterWeightRecord {
    fn is_initialized(&self) -> bool {
        self.account_discriminator == MaxVoterWeightRecord::ACCOUNT_DISCRIMINATOR
        || self.account_discriminator ==*b"9d5ff297"
    }
}