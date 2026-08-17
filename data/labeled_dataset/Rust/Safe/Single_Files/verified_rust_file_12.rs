use {
    crate::state::{
        enums::{
            GovernanceAccountType, InstructionExecutionFlags, ProposalState,
            TransactionExecutionStatus, VoteThreshold,
        },
        governance::GovernanceConfig,
        proposal_transaction::InstructionData,
        realm::RealmConfig,
    },
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        clock::{Slot, UnixTimestamp},
        program_pack::IsInitialized,
        pubkey::Pubkey,
    },
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct RealmV1 {
    pub account_type: GovernanceAccountType,
    pub community_mint: Pubkey,
    pub config: RealmConfig,
    pub reserved: [u8; 6],
    pub voting_proposal_count: u16,
    pub authority: Option<Pubkey>,
    pub name: String,
}
impl IsInitialized for RealmV1 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::RealmV1
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct TokenOwnerRecordV1 {
    pub account_type: GovernanceAccountType,
    pub realm: Pubkey,
    pub governing_token_mint: Pubkey,
    pub governing_token_owner: Pubkey,
    pub governing_token_deposit_amount: u64,
    pub unrelinquished_votes_count: u64,
    pub outstanding_proposal_count: u8,
    pub version: u8,
    pub reserved: [u8; 6],
    pub governance_delegate: Option<Pubkey>,
}
impl IsInitialized for TokenOwnerRecordV1 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::TokenOwnerRecordV1
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct GovernanceV1 {
    pub account_type: GovernanceAccountType,
    pub realm: Pubkey,
    pub governance_seed: Pubkey,
    pub proposals_count: u32,
    pub config: GovernanceConfig,
}
pub fn is_governance_v1_account_type(account_type: &GovernanceAccountType) -> bool {
    match account_type {
        GovernanceAccountType::GovernanceV1
        | GovernanceAccountType::ProgramGovernanceV1
        | GovernanceAccountType::MintGovernanceV1
        | GovernanceAccountType::TokenGovernanceV1 => true,
        GovernanceAccountType::Uninitialized
        | GovernanceAccountType::RealmV1
        | GovernanceAccountType::RealmV2
        | GovernanceAccountType::RealmConfig
        | GovernanceAccountType::TokenOwnerRecordV1
        | GovernanceAccountType::TokenOwnerRecordV2
        | GovernanceAccountType::GovernanceV2
        | GovernanceAccountType::ProgramGovernanceV2
        | GovernanceAccountType::MintGovernanceV2
        | GovernanceAccountType::TokenGovernanceV2
        | GovernanceAccountType::ProposalV1
        | GovernanceAccountType::ProposalV2
        | GovernanceAccountType::SignatoryRecordV1
        | GovernanceAccountType::SignatoryRecordV2
        | GovernanceAccountType::ProposalInstructionV1
        | GovernanceAccountType::ProposalTransactionV2
        | GovernanceAccountType::VoteRecordV1
        | GovernanceAccountType::VoteRecordV2
        | GovernanceAccountType::ProgramMetadata
        | GovernanceAccountType::ProposalDeposit
        | GovernanceAccountType::RequiredSignatory => false,
    }
}
impl IsInitialized for GovernanceV1 {
    fn is_initialized(&self) -> bool {
        is_governance_v1_account_type(&self.account_type)
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProposalV1 {
    pub account_type: GovernanceAccountType,
    pub governance: Pubkey,
    pub governing_token_mint: Pubkey,
    pub state: ProposalState,
    pub token_owner_record: Pubkey,
    pub signatories_count: u8,
    pub signatories_signed_off_count: u8,
    pub yes_votes_count: u64,
    pub no_votes_count: u64,
    pub instructions_executed_count: u16,
    pub instructions_count: u16,
    pub instructions_next_index: u16,
    pub draft_at: UnixTimestamp,
    pub signing_off_at: Option<UnixTimestamp>,
    pub voting_at: Option<UnixTimestamp>,
    pub voting_at_slot: Option<Slot>,
    pub voting_completed_at: Option<UnixTimestamp>,
    pub executing_at: Option<UnixTimestamp>,
    pub closed_at: Option<UnixTimestamp>,
    pub execution_flags: InstructionExecutionFlags,
    pub max_vote_weight: Option<u64>,
    pub vote_threshold: Option<VoteThreshold>,
    pub name: String,
    pub description_link: String,
}
impl IsInitialized for ProposalV1 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::ProposalV1
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct SignatoryRecordV1 {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub signatory: Pubkey,
    pub signed_off: bool,
}
impl IsInitialized for SignatoryRecordV1 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::SignatoryRecordV1
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProposalInstructionV1 {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub instruction_index: u16,
    pub legacy: u32,
    pub instruction: InstructionData,
    pub executed_at: Option<UnixTimestamp>,
    pub execution_status: TransactionExecutionStatus,
}
impl IsInitialized for ProposalInstructionV1 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::ProposalInstructionV1
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteWeightV1 {
    Yes(u64),
    No(u64),
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct VoteRecordV1 {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub governing_token_owner: Pubkey,
    pub is_relinquished: bool,
    pub vote_weight: VoteWeightV1,
}
impl IsInitialized for VoteRecordV1 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::VoteRecordV1
    }
}