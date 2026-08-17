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
pub enum GovernanceChatError {
    #[error("Owner doesn't have enough governing tokens to comment on Proposal")]
    NotEnoughTokensToCommentProposal = 900,
    #[error("Account already initialized")]
    AccountAlreadyInitialized,
}
impl PrintProgramError for GovernanceChatError {
    fn print<E>(&self) {
        msg!("GOVERNANCE-CHAT-ERROR: {}", &self.to_string());
    }
}
impl From<GovernanceChatError> for ProgramError {
    fn from(e: GovernanceChatError) -> Self {
        ProgramError::Custom(e as u32)
    }
}
impl<T> DecodeError<T> for GovernanceChatError {
    fn type_of() -> &'static str {
        "Governance Chat Error"
    }
}