use borsh::{BorshDeserialize, BorshSchema, BorshSerialize};
#[derive(Clone, Debug, Default, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum GovernanceAccountType {
    #[default]
    Uninitialized,
    RealmV1,
    TokenOwnerRecordV1,
    GovernanceV1,
    ProgramGovernanceV1,
    ProposalV1,
    SignatoryRecordV1,
    VoteRecordV1,
    ProposalInstructionV1,
    MintGovernanceV1,
    TokenGovernanceV1,
    RealmConfig,
    VoteRecordV2,
    ProposalTransactionV2,
    ProposalV2,
    ProgramMetadata,
    RealmV2,
    TokenOwnerRecordV2,
    GovernanceV2,
    ProgramGovernanceV2,
    MintGovernanceV2,
    TokenGovernanceV2,
    SignatoryRecordV2,
    ProposalDeposit,
    RequiredSignatory,
}
#[derive(Clone, Debug, Default, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum ProposalState {
    #[default]
    Draft,
    SigningOff,
    Voting,
    Succeeded,
    Executing,
    Completed,
    Cancelled,
    Defeated,
    ExecutingWithErrors,
    Vetoed,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteThreshold {
    YesVotePercentage(u8),
    QuorumPercentage(u8),
    Disabled,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteTipping {
    Strict,
    Early,
    Disabled,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum TransactionExecutionStatus {
    None,
    Success,
    Error,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum InstructionExecutionFlags {
    None,
    Ordered,
    UseTransaction,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum MintMaxVoterWeightSource {
    SupplyFraction(u64),
    Absolute(u64),
}
impl MintMaxVoterWeightSource {
    pub const SUPPLY_FRACTION_BASE: u64 = 10_000_000_000;
    pub const FULL_SUPPLY_FRACTION: MintMaxVoterWeightSource =
        MintMaxVoterWeightSource::SupplyFraction(MintMaxVoterWeightSource::SUPPLY_FRACTION_BASE);
}