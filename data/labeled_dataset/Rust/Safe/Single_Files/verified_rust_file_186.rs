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
pub enum SwapError {
    #[error("Swap account already in use")]
    AlreadyInUse,
    #[error("Invalid program address generated from bump seed and key")]
    InvalidProgramAddress,
    #[error("Input account owner is not the program address")]
    InvalidOwner,
    #[error("Output pool account owner cannot be the program address")]
    InvalidOutputOwner,
    #[error("Deserialized account is not an SPL Token mint")]
    ExpectedMint,
    #[error("Deserialized account is not an SPL Token account")]
    ExpectedAccount,
    #[error("Input token account empty")]
    EmptySupply,
    #[error("Pool token mint has a non-zero supply")]
    InvalidSupply,
    #[error("Token account has a delegate")]
    InvalidDelegate,
    #[error("InvalidInput")]
    InvalidInput,
    #[error("Address of the provided swap token account is incorrect")]
    IncorrectSwapAccount,
    #[error("Address of the provided pool token mint is incorrect")]
    IncorrectPoolMint,
    #[error("InvalidOutput")]
    InvalidOutput,
    #[error("General calculation failure due to overflow or underflow")]
    CalculationFailure,
    #[error("Invalid instruction")]
    InvalidInstruction,
    #[error("Swap input token accounts have the same mint")]
    RepeatedMint,
    #[error("Swap instruction exceeds desired slippage limit")]
    ExceededSlippage,
    #[error("Token account has a close authority")]
    InvalidCloseAuthority,
    #[error("Pool token mint has a freeze authority")]
    InvalidFreezeAuthority,
    #[error("Pool fee token account incorrect")]
    IncorrectFeeAccount,
    #[error("Given pool token amount results in zero trading tokens")]
    ZeroTradingTokens,
    #[error("Fee calculation failed due to overflow, underflow, or unexpected 0")]
    FeeCalculationFailure,
    #[error("Conversion to u64 failed with an overflow or underflow")]
    ConversionFailure,
    #[error("The provided fee does not match the program owner's constraints")]
    InvalidFee,
    #[error("The provided token program does not match the token program expected by the swap")]
    IncorrectTokenProgramId,
    #[error("The provided curve type is not supported by the program owner")]
    UnsupportedCurveType,
    #[error("The provided curve parameters are invalid")]
    InvalidCurve,
    #[error("The operation cannot be performed on the given curve")]
    UnsupportedCurveOperation,
    #[error("The pool fee account is invalid")]
    InvalidFeeAccount,
}
impl From<SwapError> for ProgramError {
    fn from(e: SwapError) -> Self {
        ProgramError::Custom(e as u32)
    }
}
impl<T> DecodeError<T> for SwapError {
    fn type_of() -> &'static str {
        "Swap Error"
    }
}
impl PrintProgramError for SwapError {
    fn print<E>(&self)
    where
        E: 'static
            + std::error::Error
            + DecodeError<E>
            + PrintProgramError
            + num_traits::FromPrimitive,
    {
        match self {
            SwapError::AlreadyInUse => msg!("Error: Swap account already in use"),
            SwapError::InvalidProgramAddress => {
                msg!("Error: Invalid program address generated from bump seed and key")
            }
            SwapError::InvalidOwner => {
                msg!("Error: The input account owner is not the program address")
            }
            SwapError::InvalidOutputOwner => {
                msg!("Error: Output pool account owner cannot be the program address")
            }
            SwapError::ExpectedMint => msg!("Error: Deserialized account is not an SPL Token mint"),
            SwapError::ExpectedAccount => {
                msg!("Error: Deserialized account is not an SPL Token account")
            }
            SwapError::EmptySupply => msg!("Error: Input token account empty"),
            SwapError::InvalidSupply => msg!("Error: Pool token mint has a non-zero supply"),
            SwapError::RepeatedMint => msg!("Error: Swap input token accounts have the same mint"),
            SwapError::InvalidDelegate => msg!("Error: Token account has a delegate"),
            SwapError::InvalidInput => msg!("Error: InvalidInput"),
            SwapError::IncorrectSwapAccount => {
                msg!("Error: Address of the provided swap token account is incorrect")
            }
            SwapError::IncorrectPoolMint => {
                msg!("Error: Address of the provided pool token mint is incorrect")
            }
            SwapError::InvalidOutput => msg!("Error: InvalidOutput"),
            SwapError::CalculationFailure => msg!("Error: CalculationFailure"),
            SwapError::InvalidInstruction => msg!("Error: InvalidInstruction"),
            SwapError::ExceededSlippage => {
                msg!("Error: Swap instruction exceeds desired slippage limit")
            }
            SwapError::InvalidCloseAuthority => msg!("Error: Token account has a close authority"),
            SwapError::InvalidFreezeAuthority => {
                msg!("Error: Pool token mint has a freeze authority")
            }
            SwapError::IncorrectFeeAccount => msg!("Error: Pool fee token account incorrect"),
            SwapError::ZeroTradingTokens => {
                msg!("Error: Given pool token amount results in zero trading tokens")
            }
            SwapError::FeeCalculationFailure => msg!(
                "Error: The fee calculation failed due to overflow, underflow, or unexpected 0"
            ),
            SwapError::ConversionFailure => msg!("Error: Conversion to or from u64 failed."),
            SwapError::InvalidFee => {
                msg!("Error: The provided fee does not match the program owner's constraints")
            }
            SwapError::IncorrectTokenProgramId => {
                msg!("Error: The provided token program does not match the token program expected by the swap")
            }
            SwapError::UnsupportedCurveType => {
                msg!("Error: The provided curve type is not supported by the program owner")
            }
            SwapError::InvalidCurve => {
                msg!("Error: The provided curve parameters are invalid")
            }
            SwapError::UnsupportedCurveOperation => {
                msg!("Error: The operation cannot be performed on the given curve")
            }
            SwapError::InvalidFeeAccount => {
                msg!("Error: The pool fee account is invalid")
            }
        }
    }
}