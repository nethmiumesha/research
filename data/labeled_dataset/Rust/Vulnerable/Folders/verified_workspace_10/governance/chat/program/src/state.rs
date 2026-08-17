use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::AccountInfo, clock::UnixTimestamp, program_error::ProgramError,
        pubkey::Pubkey,
    },
    spl_governance_tools::account::{assert_is_valid_account_of_type, AccountMaxSize},
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum GovernanceChatAccountType {
    Uninitialized,
    ChatMessage,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum MessageBody {
    Text(String),
    Reaction(String),
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ChatMessage {
    pub account_type: GovernanceChatAccountType,
    pub proposal: Pubkey,
    pub author: Pubkey,
    pub posted_at: UnixTimestamp,
    pub reply_to: Option<Pubkey>,
    pub body: MessageBody,
}
impl AccountMaxSize for ChatMessage {
    fn get_max_size(&self) -> Option<usize> {
        let body_size = match &self.body {
            MessageBody::Text(body) => body.len(),
            MessageBody::Reaction(body) => body.len(),
        };
        Some(body_size + 111)
    }
}
pub fn assert_is_valid_chat_message(
    program_id: &Pubkey,
    chat_message_info: &AccountInfo,
) -> Result<(), ProgramError> {
    assert_is_valid_account_of_type(
        program_id,
        chat_message_info,
        GovernanceChatAccountType::ChatMessage,
    )
}