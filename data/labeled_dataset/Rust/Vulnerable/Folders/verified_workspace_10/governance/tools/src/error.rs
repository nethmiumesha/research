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
pub enum GovernanceToolsError {
    #[error("Account already initialized")]
    AccountAlreadyInitialized = 1100,
    #[error("Account doesn't exist")]
    AccountDoesNotExist,
    #[error("Invalid account owner")]
    InvalidAccountOwner,
    #[error("Invalid account type")]
    InvalidAccountType,
    #[error("Invalid new account size")]
    InvalidNewAccountSize,
}
impl PrintProgramError for GovernanceToolsError {
    fn print<E>(&self) {
        msg!("GOVERNANCE-TOOLS-ERROR: {}", &self.to_string());
    }
}
impl From<GovernanceToolsError> for ProgramError {
    fn from(e: GovernanceToolsError) -> Self {
        ProgramError::Custom(e as u32)
    }
}
impl<T> DecodeError<T> for GovernanceToolsError {
    fn type_of() -> &'static str {
        "Governance Tools Error"
    }
}