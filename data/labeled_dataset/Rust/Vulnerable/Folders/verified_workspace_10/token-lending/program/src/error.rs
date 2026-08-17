use {
    num_derive::FromPrimitive,
    solana_program::{decode_error::DecodeError, program_error::ProgramError},
    thiserror::Error,
};
#[derive(Clone, Debug, Eq, Error, FromPrimitive, PartialEq)]
pub enum LendingError {
    #[error("Failed to unpack instruction data")]
    InstructionUnpackError,
    #[error("Account is already initialized")]
    AlreadyInitialized,
    #[error("Lamport balance below rent-exempt threshold")]
    NotRentExempt,
    #[error("Market authority is invalid")]
    InvalidMarketAuthority,
    #[error("Market owner is invalid")]
    InvalidMarketOwner,
    #[error("Input account owner is not the program address")]
    InvalidAccountOwner,
    #[error("Input token account is not owned by the correct token program id")]
    InvalidTokenOwner,
    #[error("Input token account is not valid")]
    InvalidTokenAccount,
    #[error("Input token mint account is not valid")]
    InvalidTokenMint,
    #[error("Input token program account is not valid")]
    InvalidTokenProgram,
    #[error("Input amount is invalid")]
    InvalidAmount,
    #[error("Input config value is invalid")]
    InvalidConfig,
    #[error("Input account must be a signer")]
    InvalidSigner,
    #[error("Invalid account input")]
    InvalidAccountInput,
    #[error("Math operation overflow")]
    MathOverflow,
    #[error("Token initialize mint failed")]
    TokenInitializeMintFailed,
    #[error("Token initialize account failed")]
    TokenInitializeAccountFailed,
    #[error("Token transfer failed")]
    TokenTransferFailed,
    #[error("Token mint to failed")]
    TokenMintToFailed,
    #[error("Token burn failed")]
    TokenBurnFailed,
    #[error("Insufficient liquidity available")]
    InsufficientLiquidity,
    #[error("Input reserve has collateral disabled")]
    ReserveCollateralDisabled,
    #[error("Reserve state needs to be refreshed")]
    ReserveStale,
    #[error("Withdraw amount too small")]
    WithdrawTooSmall,
    #[error("Withdraw amount too large")]
    WithdrawTooLarge,
    #[error("Borrow amount too small to receive liquidity after fees")]
    BorrowTooSmall,
    #[error("Borrow amount too large for deposited collateral")]
    BorrowTooLarge,
    #[error("Repay amount too small to transfer liquidity")]
    RepayTooSmall,
    #[error("Liquidation amount too small to receive collateral")]
    LiquidationTooSmall,
    #[error("Cannot liquidate healthy obligations")]
    ObligationHealthy,
    #[error("Obligation state needs to be refreshed")]
    ObligationStale,
    #[error("Obligation reserve limit exceeded")]
    ObligationReserveLimit,
    #[error("Obligation owner is invalid")]
    InvalidObligationOwner,
    #[error("Obligation deposits are empty")]
    ObligationDepositsEmpty,
    #[error("Obligation borrows are empty")]
    ObligationBorrowsEmpty,
    #[error("Obligation deposits have zero value")]
    ObligationDepositsZero,
    #[error("Obligation borrows have zero value")]
    ObligationBorrowsZero,
    #[error("Invalid obligation collateral")]
    InvalidObligationCollateral,
    #[error("Invalid obligation liquidity")]
    InvalidObligationLiquidity,
    #[error("Obligation collateral is empty")]
    ObligationCollateralEmpty,
    #[error("Obligation liquidity is empty")]
    ObligationLiquidityEmpty,
    #[error("Interest rate is negative")]
    NegativeInterestRate,
    #[error("Input oracle config is invalid")]
    InvalidOracleConfig,
    #[error("Input flash loan receiver program account is not valid")]
    InvalidFlashLoanReceiverProgram,
    #[error("Not enough liquidity after flash loan")]
    NotEnoughLiquidityAfterFlashLoan,
    #[error("Amount smaller than desired slippage limit")]
    ExceededSlippage,
}
impl From<LendingError> for ProgramError {
    fn from(e: LendingError) -> Self {
        ProgramError::Custom(e as u32)
    }
}
impl<T> DecodeError<T> for LendingError {
    fn type_of() -> &'static str {
        "Lending Error"
    }
}