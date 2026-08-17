use {
    num_derive::FromPrimitive,
    solana_program::{
        decode_error::DecodeError,
        msg,
        program_error::{PrintProgramError, ProgramError},
    },
    thiserror::Error,
};
#[derive(Clone, Debug, Eq, Error, FromPrimitive, PartialEq)]
pub enum GovernanceError {
    #[error("Invalid instruction passed to program")]
    InvalidInstruction = 500,
    #[error("Realm with the given name and governing mints already exists")]
    RealmAlreadyExists,
    #[error("Invalid realm")]
    InvalidRealm,
    #[error("Invalid Governing Token Mint")]
    InvalidGoverningTokenMint,
    #[error("Governing Token Owner must sign transaction")]
    GoverningTokenOwnerMustSign,
    #[error("Governing Token Owner or Delegate  must sign transaction")]
    GoverningTokenOwnerOrDelegateMustSign,
    #[error("All votes must be relinquished to withdraw governing tokens")]
    AllVotesMustBeRelinquishedToWithdrawGoverningTokens,
    #[error("Invalid Token Owner Record account address")]
    InvalidTokenOwnerRecordAccountAddress,
    #[error("Invalid GoverningMint for TokenOwnerRecord")]
    InvalidGoverningMintForTokenOwnerRecord,
    #[error("Invalid Realm for TokenOwnerRecord")]
    InvalidRealmForTokenOwnerRecord,
    #[error("Invalid Proposal for ProposalTransaction,")]
    InvalidProposalForProposalTransaction,
    #[error("Invalid Signatory account address")]
    InvalidSignatoryAddress,
    #[error("Signatory already signed off")]
    SignatoryAlreadySignedOff,
    #[error("Signatory must sign")]
    SignatoryMustSign,
    #[error("Invalid Proposal Owner")]
    InvalidProposalOwnerAccount,
    #[error("Invalid Proposal for VoterRecord")]
    InvalidProposalForVoterRecord,
    #[error("Invalid GoverningTokenOwner for VoteRecord")]
    InvalidGoverningTokenOwnerForVoteRecord,
    #[error("Invalid Governance config: Vote threshold percentage out of range")]
    InvalidVoteThresholdPercentage,
    #[error("Proposal for the given Governance, Governing Token Mint and index already exists")]
    ProposalAlreadyExists,
    #[error("Token Owner already voted on the Proposal")]
    VoteAlreadyExists,
    #[error("Owner doesn't have enough governing tokens to create Proposal")]
    NotEnoughTokensToCreateProposal,
    #[error("Invalid State: Can't edit Signatories")]
    InvalidStateCannotEditSignatories,
    #[error("Invalid Proposal state")]
    InvalidProposalState,
    #[error("Invalid State: Can't edit transactions")]
    InvalidStateCannotEditTransactions,
    #[error("Invalid State: Can't execute transaction")]
    InvalidStateCannotExecuteTransaction,
    #[error("Can't execute transaction within its hold up time")]
    CannotExecuteTransactionWithinHoldUpTime,
    #[error("Transaction already executed")]
    TransactionAlreadyExecuted,
    #[error("Invalid Transaction index")]
    InvalidTransactionIndex,
    #[error("Legacy3")]
    Legacy3,
    #[error("Transaction at the given index for the Proposal already exists")]
    TransactionAlreadyExists,
    #[error("Invalid State: Can't sign off")]
    InvalidStateCannotSignOff,
    #[error("Invalid State: Can't vote")]
    InvalidStateCannotVote,
    #[error("Invalid State: Can't finalize vote")]
    InvalidStateCannotFinalize,
    #[error("Invalid State: Can't cancel Proposal")]
    InvalidStateCannotCancelProposal,
    #[error("Vote already relinquished")]
    VoteAlreadyRelinquished,
    #[error("Can't finalize vote. Voting still in progress")]
    CannotFinalizeVotingInProgress,
    #[error("Proposal voting time expired")]
    ProposalVotingTimeExpired,
    #[error("Invalid Signatory Mint")]
    InvalidSignatoryMint,
    #[error("Proposal does not belong to the given Governance")]
    InvalidGovernanceForProposal,
    #[error("Proposal does not belong to given Governing Mint")]
    InvalidGoverningMintForProposal,
    #[error("Current mint authority must sign transaction")]
    MintAuthorityMustSign,
    #[error("Invalid mint authority")]
    InvalidMintAuthority,
    #[error("Mint has no authority")]
    MintHasNoAuthority,
    #[error("Invalid Token account owner")]
    SplTokenAccountWithInvalidOwner,
    #[error("Invalid Mint account owner")]
    SplTokenMintWithInvalidOwner,
    #[error("Token Account is not initialized")]
    SplTokenAccountNotInitialized,
    #[error("Token Account doesn't exist")]
    SplTokenAccountDoesNotExist,
    #[error("Token account data is invalid")]
    SplTokenInvalidTokenAccountData,
    #[error("Token mint account data is invalid")]
    SplTokenInvalidMintAccountData,
    #[error("Token Mint account is not initialized")]
    SplTokenMintNotInitialized,
    #[error("Token Mint account doesn't exist")]
    SplTokenMintDoesNotExist,
    #[error("Invalid ProgramData account address")]
    InvalidProgramDataAccountAddress,
    #[error("Invalid ProgramData account Data")]
    InvalidProgramDataAccountData,
    #[error("Provided upgrade authority doesn't match current program upgrade authority")]
    InvalidUpgradeAuthority,
    #[error("Current program upgrade authority must sign transaction")]
    UpgradeAuthorityMustSign,
    #[error("Given program is not upgradable")]
    ProgramNotUpgradable,
    #[error("Invalid token owner")]
    InvalidTokenOwner,
    #[error("Current token owner must sign transaction")]
    TokenOwnerMustSign,
    #[error("Given VoteThresholdType is not supported")]
    VoteThresholdTypeNotSupported,
    #[error("Given VoteWeightSource is not supported")]
    VoteWeightSourceNotSupported,
    #[error("Legacy1")]
    Legacy1,
    #[error("Governance PDA must sign")]
    GovernancePdaMustSign,
    #[error("Legacy2")]
    Legacy2,
    #[error("Invalid Realm for Governance")]
    InvalidRealmForGovernance,
    #[error("Invalid Authority for Realm")]
    InvalidAuthorityForRealm,
    #[error("Realm has no authority")]
    RealmHasNoAuthority,
    #[error("Realm authority must sign")]
    RealmAuthorityMustSign,
    #[error("Invalid governing token holding account")]
    InvalidGoverningTokenHoldingAccount,
    #[error("Realm council mint change is not supported")]
    RealmCouncilMintChangeIsNotSupported,
    #[error("Invalid max voter weight absolute value")]
    InvalidMaxVoterWeightAbsoluteValue,
    #[error("Invalid max voter weight supply fraction")]
    InvalidMaxVoterWeightSupplyFraction,
    #[error("Owner doesn't have enough governing tokens to create Governance")]
    NotEnoughTokensToCreateGovernance,
    #[error("Too many outstanding proposals")]
    TooManyOutstandingProposals,
    #[error("All proposals must be finalized to withdraw governing tokens")]
    AllProposalsMustBeFinalisedToWithdrawGoverningTokens,
    #[error("Invalid VoterWeightRecord for Realm")]
    InvalidVoterWeightRecordForRealm,
    #[error("Invalid VoterWeightRecord for GoverningTokenMint")]
    InvalidVoterWeightRecordForGoverningTokenMint,
    #[error("Invalid VoterWeightRecord for TokenOwner")]
    InvalidVoterWeightRecordForTokenOwner,
    #[error("VoterWeightRecord expired")]
    VoterWeightRecordExpired,
    #[error("Invalid RealmConfig for Realm")]
    InvalidRealmConfigForRealm,
    #[error("TokenOwnerRecord already exists")]
    TokenOwnerRecordAlreadyExists,
    #[error("Governing token deposits not allowed")]
    GoverningTokenDepositsNotAllowed,
    #[error("Invalid vote choice weight percentage")]
    InvalidVoteChoiceWeightPercentage,
    #[error("Vote type not supported")]
    VoteTypeNotSupported,
    #[error("Invalid proposal options")]
    InvalidProposalOptions,
    #[error("Proposal is not executable")]
    ProposalIsNotExecutable,
    #[error("Deny vote is not allowed")]
    DenyVoteIsNotAllowed,
    #[error("Cannot execute defeated option")]
    CannotExecuteDefeatedOption,
    #[error("VoterWeightRecord invalid action")]
    VoterWeightRecordInvalidAction,
    #[error("VoterWeightRecord invalid action target")]
    VoterWeightRecordInvalidActionTarget,
    #[error("Invalid MaxVoterWeightRecord for Realm")]
    InvalidMaxVoterWeightRecordForRealm,
    #[error("Invalid MaxVoterWeightRecord for GoverningTokenMint")]
    InvalidMaxVoterWeightRecordForGoverningTokenMint,
    #[error("MaxVoterWeightRecord expired")]
    MaxVoterWeightRecordExpired,
    #[error("Not supported VoteType")]
    NotSupportedVoteType,
    #[error("RealmConfig change not allowed")]
    RealmConfigChangeNotAllowed,
    #[error("GovernanceConfig change not allowed")]
    GovernanceConfigChangeNotAllowed,
    #[error("At least one VoteThreshold is required")]
    AtLeastOneVoteThresholdRequired,
    #[error("Reserved buffer must be empty")]
    ReservedBufferMustBeEmpty,
    #[error("Cannot Relinquish in Finalizing state")]
    CannotRelinquishInFinalizingState,
    #[error("Invalid RealmConfig account address")]
    InvalidRealmConfigAddress,
    #[error("Cannot deposit dormant tokens")]
    CannotDepositDormantTokens,
    #[error("Cannot withdraw membership tokens")]
    CannotWithdrawMembershipTokens,
    #[error("Cannot revoke GoverningTokens")]
    CannotRevokeGoverningTokens,
    #[error("Invalid Revoke amount")]
    InvalidRevokeAmount,
    #[error("Invalid GoverningToken source")]
    InvalidGoverningTokenSource,
    #[error("Cannot change community TokenType to Membership")]
    CannotChangeCommunityTokenTypeToMembership,
    #[error("Voter weight threshold disabled")]
    VoterWeightThresholdDisabled,
    #[error("Vote not allowed in cool off time")]
    VoteNotAllowedInCoolOffTime,
    #[error("Cannot refund ProposalDeposit")]
    CannotRefundProposalDeposit,
    #[error("Invalid Proposal for ProposalDeposit")]
    InvalidProposalForProposalDeposit,
    #[error("Invalid deposit_exempt_proposal_count")]
    InvalidDepositExemptProposalCount,
    #[error("GoverningTokenMint not allowed to vote")]
    GoverningTokenMintNotAllowedToVote,
    #[error("Invalid deposit Payer for ProposalDeposit")]
    InvalidDepositPayerForProposalDeposit,
    #[error("Invalid State: Proposal is not in final state")]
    InvalidStateNotFinal,
    #[error("Invalid state for proposal state transition to Completed")]
    InvalidStateToCompleteProposal,
    #[error("Invalid number of vote choices")]
    InvalidNumberOfVoteChoices,
    #[error("Ranked vote is not supported")]
    RankedVoteIsNotSupported,
    #[error("Choice weight must be 100%")]
    ChoiceWeightMustBe100Percent,
    #[error("Single choice only is allowed")]
    SingleChoiceOnlyIsAllowed,
    #[error("At least single choice is required")]
    AtLeastSingleChoiceIsRequired,
    #[error("Total vote weight must be 100%")]
    TotalVoteWeightMustBe100Percent,
    #[error("Invalid multi choice proposal parameters")]
    InvalidMultiChoiceProposalParameters,
    #[error("Invalid Governance for RequiredSignatory")]
    InvalidGovernanceForRequiredSignatory,
    #[error("Signatory Record has already been created")]
    SignatoryRecordAlreadyExists,
    #[error("Instruction has been removed")]
    InstructionDeprecated,
    #[error("Proposal is missing required signatories")]
    MissingRequiredSignatories,
    #[error("TokenOwnerRecordLock authority must sign")]
    TokenOwnerRecordLockAuthorityMustSign,
    #[error("TokenOwnerRecordLock is expired ")]
    ExpiredTokenOwnerRecordLock,
    #[error("TokenOwnerRecord locked")]
    TokenOwnerRecordLocked,
    #[error("Invalid TokenOwnerRecordLockAuthority")]
    InvalidTokenOwnerRecordLockAuthority,
    #[error("TokenOwnerRecordLock authority already exists")]
    TokenOwnerRecordLockAuthorityAlreadyExists,
    #[error("TokenOwnerRecordLock not found")]
    TokenOwnerRecordLockNotFound,
    #[error("TokenOwnerRecordLockAuthority not found")]
    TokenOwnerRecordLockAuthorityNotFound,
}
impl PrintProgramError for GovernanceError {
    fn print<E>(&self) {
        msg!("GOVERNANCE-ERROR: {}", &self.to_string());
    }
}
impl From<GovernanceError> for ProgramError {
    fn from(e: GovernanceError) -> Self {
        ProgramError::Custom(e as u32)
    }
}
impl<T> DecodeError<T> for GovernanceError {
    fn type_of() -> &'static str {
        "Governance Error"
    }
}