use anchor_lang::prelude::*;
#[error_code]
pub enum MarinadeError {
    #[msg("Wrong reserve owner. Must be a system account")]
    WrongReserveOwner,
    #[msg("Reserve must have no data, but has data")]
    NonEmptyReserveData,
    #[msg("Invalid initial reserve lamports")]
    InvalidInitialReserveLamports,
    #[msg("Zero validator chunk size")]
    ZeroValidatorChunkSize,
    #[msg("Too big validator chunk size")]
    TooBigValidatorChunkSize,
    #[msg("Zero credit chunk size")]
    ZeroCreditChunkSize,
    #[msg("Too big credit chunk size")]
    TooBigCreditChunkSize,
    #[msg("Too low credit fee")]
    TooLowCreditFee,
    #[msg("Invalid mint authority")]
    InvalidMintAuthority,
    #[msg("Non empty initial mint supply")]
    MintHasInitialSupply,
    #[msg("Invalid owner fee state")]
    InvalidOwnerFeeState,
    #[msg(
        "Invalid program id. For using program from another account please update id in the code"
    )]
    InvalidProgramId,
    #[msg("Unexpected account")]
    UnexpectedAccount,
    #[msg("Calculation failure")]
    CalculationFailure,
    #[msg("You can't deposit a stake-account with lockup")]
    StakeAccountWithLockup,
    #[msg("Min stake is too low")]
    MinStakeIsTooLow,
    #[msg("Lp max fee is too high")]
    LpMaxFeeIsTooHigh,
    #[msg("Basis points overflow")]
    BasisPointsOverflow,
    #[msg("LP min fee > LP max fee")]
    LpFeesAreWrongWayRound,
    #[msg("Liquidity target too low")]
    LiquidityTargetTooLow,
    #[msg("Ticket not due. Wait more epochs")]
    TicketNotDue,
    #[msg("Ticket not ready. Wait a few hours and try again")]
    TicketNotReady,
    #[msg("Wrong Ticket Beneficiary")]
    WrongBeneficiary,
    #[msg("Stake Account not updated yet")]
    StakeAccountNotUpdatedYet,
    #[msg("Stake Account not delegated")]
    StakeNotDelegated,
    #[msg("Stake Account is emergency unstaking")]
    StakeAccountIsEmergencyUnstaking,
    #[msg("Insufficient Liquidity in the Liquidity Pool")]
    InsufficientLiquidity,
    NotUsed6027,
    #[msg("Invalid admin authority")]
    InvalidAdminAuthority,
    #[msg("Invalid validator system manager")]
    InvalidValidatorManager,
    #[msg("Invalid stake list account discriminator")]
    InvalidStakeListDiscriminator,
    #[msg("Invalid validator list account discriminator")]
    InvalidValidatorListDiscriminator,
    #[msg("Treasury cut is too high")]
    TreasuryCutIsTooHigh,
    #[msg("Reward fee is too high")]
    RewardsFeeIsTooHigh,
    #[msg("Staking is capped")]
    StakingIsCapped,
    #[msg("Liquidity is capped")]
    LiquidityIsCapped,
    #[msg("Update window is too low")]
    UpdateWindowIsTooLow,
    #[msg("Min withdraw is too high")]
    MinWithdrawIsTooHigh,
    #[msg("Withdraw amount is too low")]
    WithdrawAmountIsTooLow,
    #[msg("Deposit amount is too low")]
    DepositAmountIsTooLow,
    #[msg("Not enough user funds")]
    NotEnoughUserFunds,
    #[msg("Wrong token owner or delegate")]
    WrongTokenOwnerOrDelegate,
    #[msg("Too early for stake delta")]
    TooEarlyForStakeDelta,
    #[msg("Required delegated stake")]
    RequiredDelegatedStake,
    #[msg("Required active stake")]
    RequiredActiveStake,
    #[msg("Required deactivating stake")]
    RequiredDeactivatingStake,
    #[msg("Depositing not activated stake")]
    DepositingNotActivatedStake,
    #[msg("Too low delegation in the depositing stake")]
    TooLowDelegationInDepositingStake,
    #[msg("Wrong deposited stake balance")]
    WrongStakeBalance,
    #[msg("Wrong validator account or index")]
    WrongValidatorAccountOrIndex,
    #[msg("Wrong stake account or index")]
    WrongStakeAccountOrIndex,
    #[msg("Delta stake is positive so we must stake instead of unstake")]
    UnstakingOnPositiveDelta,
    #[msg("Delta stake is negative so we must unstake instead of stake")]
    StakingOnNegativeDelta,
    #[msg("Moving stake during an epoch is capped")]
    MovingStakeIsCapped,
    #[msg("Stake must be uninitialized")]
    StakeMustBeUninitialized,
    #[msg("Destination stake must be delegated")]
    DestinationStakeMustBeDelegated,
    #[msg("Destination stake must not be deactivating")]
    DestinationStakeMustNotBeDeactivating,
    #[msg("Destination stake must be updated")]
    DestinationStakeMustBeUpdated,
    #[msg("Invalid destination stake delegation")]
    InvalidDestinationStakeDelegation,
    #[msg("Source stake must be delegated")]
    SourceStakeMustBeDelegated,
    #[msg("Source stake must not be deactivating")]
    SourceStakeMustNotBeDeactivating,
    #[msg("Source stake must be updated")]
    SourceStakeMustBeUpdated,
    #[msg("Invalid source stake delegation")]
    InvalidSourceStakeDelegation,
    #[msg("Invalid delayed unstake ticket")]
    InvalidDelayedUnstakeTicket,
    #[msg("Reusing delayed unstake ticket")]
    ReusingDelayedUnstakeTicket,
    #[msg("Emergency unstaking from non zero scored validator")]
    EmergencyUnstakingFromNonZeroScoredValidator,
    #[msg("Wrong validator duplication flag")]
    WrongValidatorDuplicationFlag,
    #[msg("Redepositing marinade stake")]
    RedepositingMarinadeStake,
    #[msg("Removing validator with balance")]
    RemovingValidatorWithBalance,
    #[msg("Redelegate will put validator over stake target")]
    RedelegateOverTarget,
    #[msg("Source and Dest Validators are the same")]
    SourceAndDestValidatorsAreTheSame,
    #[msg("Some mSOL tokens was minted outside of marinade contract")]
    UnregisteredMsolMinted,
    #[msg("Some LP tokens was minted outside of marinade contract")]
    UnregisteredLPMinted,
    #[msg("List index out of bounds")]
    ListIndexOutOfBounds,
    #[msg("List overflow")]
    ListOverflow,
    #[msg("Requested pause and already Paused")]
    AlreadyPaused,
    #[msg("Requested resume, but not Paused")]
    NotPaused,
    #[msg("Emergency Pause is Active")]
    ProgramIsPaused,
    #[msg("Invalid pause authority")]
    InvalidPauseAuthority,
    #[msg("Selected Stake account has not enough funds")]
    SelectedStakeAccountHasNotEnoughFunds,
    #[msg("Basis point CENTS overflow")]
    BasisPointCentsOverflow,
    #[msg("Withdraw stake account is not enabled")]
    WithdrawStakeAccountIsNotEnabled,
    #[msg("Withdraw stake account fee is too high")]
    WithdrawStakeAccountFeeIsTooHigh,
    #[msg("Delayed unstake fee is too high")]
    DelayedUnstakeFeeIsTooHigh,
    #[msg("Withdraw stake account value is too low")]
    WithdrawStakeLamportsIsTooLow,
    #[msg("Stake account remainder too low")]
    StakeAccountRemainderTooLow,
    #[msg("Capacity of the list must be not less than it's current size")]
    ShrinkingListWithDeletingContents,
}