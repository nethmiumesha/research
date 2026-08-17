use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::pubkey::Pubkey,
    spl_governance::state::{enums::GovernanceAccountType, governance::GovernanceV2},
};
#[derive(Clone, Debug, PartialEq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct LegacyGovernanceV1 {
    pub account_type: GovernanceAccountType,
    pub realm: Pubkey,
    pub governance_seed: Pubkey,
    pub proposals_count: u32,
    pub config: LegacyGovernanceConfigV1,
    pub reserved: [u8; 8],
}
#[derive(Clone, Debug, PartialEq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct LegacyGovernanceConfigV1 {
    pub vote_threshold_percentage: VoteThresholdPercentage,
    pub min_community_tokens_to_create_proposal: u64,
    pub transactions_hold_up_time: u32,
    pub max_voting_time: u32,
    pub vote_weight_source: VoteWeightSource,
    pub proposal_cool_off_time: u32,
    pub min_council_tokens_to_create_proposal: u64,
}
#[derive(Clone, Debug, PartialEq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteWeightSource {
    Deposit,
    Snapshot,
}
#[repr(C)]
#[derive(Clone, Debug, PartialEq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteThresholdPercentage {
    YesVote(u8),
    Quorum(u8),
}
impl From<GovernanceV2> for LegacyGovernanceV1 {
    fn from(governance_v2: GovernanceV2) -> Self {
        let account_type = match governance_v2.account_type {
            GovernanceAccountType::GovernanceV2 => GovernanceAccountType::GovernanceV1,
            GovernanceAccountType::ProgramGovernanceV2 => {
                GovernanceAccountType::ProgramGovernanceV1
            }
            GovernanceAccountType::MintGovernanceV2 => GovernanceAccountType::MintGovernanceV1,
            GovernanceAccountType::TokenGovernanceV2 => GovernanceAccountType::TokenGovernanceV1,
            _ => panic!("Invalid Governance account type"),
        };
        let yes_vote_threshold = match governance_v2.config.community_vote_threshold {
            spl_governance::state::enums::VoteThreshold::YesVotePercentage(yes_vote_percentage) => {
                yes_vote_percentage
            }
            _ => panic!("Invalid vote threshold"),
        };
        LegacyGovernanceV1 {
            account_type,
            realm: governance_v2.realm,
            governance_seed: governance_v2.governance_seed,
            proposals_count: 0,
            config: LegacyGovernanceConfigV1 {
                vote_threshold_percentage: VoteThresholdPercentage::YesVote(yes_vote_threshold),
                min_community_tokens_to_create_proposal: governance_v2
                    .config
                    .min_community_weight_to_create_proposal,
                transactions_hold_up_time: governance_v2.config.transactions_hold_up_time,
                max_voting_time: governance_v2.config.voting_base_time,
                vote_weight_source: VoteWeightSource::Deposit,
                proposal_cool_off_time: 0,
                min_council_tokens_to_create_proposal: governance_v2
                    .config
                    .min_council_weight_to_create_proposal,
            },
            reserved: [0; 8],
        }
    }
}