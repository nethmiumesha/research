use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{clock::Slot, program_pack::IsInitialized, pubkey::Pubkey},
    spl_governance_tools::account::AccountMaxSize,
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoterWeightAction {
    CastVote,
    CommentProposal,
    CreateGovernance,
    CreateProposal,
    SignOffProposal,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct VoterWeightRecord {
    pub account_discriminator: [u8; 8],
    pub realm: Pubkey,
    pub governing_token_mint: Pubkey,
    pub governing_token_owner: Pubkey,
    pub voter_weight: u64,
    pub voter_weight_expiry: Option<Slot>,
    pub weight_action: Option<VoterWeightAction>,
    pub weight_action_target: Option<Pubkey>,
    pub reserved: [u8; 8],
}
impl VoterWeightRecord {
    pub const ACCOUNT_DISCRIMINATOR: [u8; 8] = [46, 249, 155, 75, 153, 248, 116, 9];
}
impl AccountMaxSize for VoterWeightRecord {}
impl IsInitialized for VoterWeightRecord {
    fn is_initialized(&self) -> bool {
        self.account_discriminator == VoterWeightRecord::ACCOUNT_DISCRIMINATOR
            || self.account_discriminator == *b"2ef99b4b"
    }
}