#![cfg(feature = "test-sbf")]
use {
    program_test::GovernanceChatProgramTest, solana_program_test::tokio,
    solana_sdk::signature::Keypair, spl_governance::error::GovernanceError,
    spl_governance_chat::error::GovernanceChatError,
};
mod program_test;
#[tokio::test]
async fn test_post_message() {
    let mut governance_chat_test = GovernanceChatProgramTest::start_new().await;
    let proposal_cookie = governance_chat_test.with_proposal().await;
    let chat_message_cookie = governance_chat_test
        .with_chat_message(&proposal_cookie, None)
        .await
        .unwrap();
    let chat_message_data = governance_chat_test
        .get_message_account(&chat_message_cookie.address)
        .await;
    assert_eq!(chat_message_data, chat_message_cookie.account);
}
#[tokio::test]
async fn test_post_reply_message() {
    let mut governance_chat_test = GovernanceChatProgramTest::start_new().await;
    let proposal_cookie = governance_chat_test.with_proposal().await;
    let chat_message_cookie1 = governance_chat_test
        .with_chat_message(&proposal_cookie, None)
        .await
        .unwrap();
    let chat_message_cookie2 = governance_chat_test
        .with_chat_message(&proposal_cookie, Some(chat_message_cookie1.address))
        .await
        .unwrap();
    let chat_message_data = governance_chat_test
        .get_message_account(&chat_message_cookie2.address)
        .await;
    assert_eq!(chat_message_data, chat_message_cookie2.account);
}
#[tokio::test]
async fn test_post_message_with_owner_or_delegate_must_sign_error() {
    let mut governance_chat_test = GovernanceChatProgramTest::start_new().await;
    let mut proposal_cookie = governance_chat_test.with_proposal().await;
    proposal_cookie.token_owner = Keypair::new();
    let err = governance_chat_test
        .with_chat_message(&proposal_cookie, None)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenOwnerOrDelegateMustSign.into()
    );
}
#[tokio::test]
async fn test_post_message_with_invalid_governance_for_proposal_error() {
    let mut governance_chat_test = GovernanceChatProgramTest::start_new().await;
    let proposal_cookie1 = governance_chat_test.with_proposal().await;
    let mut proposal_cookie2 = governance_chat_test.with_proposal().await;
    proposal_cookie2.address = proposal_cookie1.address;
    let err = governance_chat_test
        .with_chat_message(&proposal_cookie2, None)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidGovernanceForProposal.into());
}
#[tokio::test]
async fn test_post_message_with_not_enough_tokens_error() {
    let mut governance_chat_test = GovernanceChatProgramTest::start_new().await;
    let mut proposal_cookie = governance_chat_test.with_proposal().await;
    let token_owner_record_cookie = governance_chat_test
        .with_token_owner_deposit(&proposal_cookie, 0)
        .await;
    proposal_cookie.token_owner_record_address = token_owner_record_cookie.address;
    proposal_cookie.token_owner = token_owner_record_cookie.token_owner;
    let err = governance_chat_test
        .with_chat_message(&proposal_cookie, None)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceChatError::NotEnoughTokensToCommentProposal.into()
    );
}
#[tokio::test]
async fn test_post_message_with_voter_weight_addin() {
    let mut governance_chat_test = GovernanceChatProgramTest::start_with_voter_weight_addin().await;
    let proposal_cookie = governance_chat_test.with_proposal().await;
    let chat_message_cookie = governance_chat_test
        .with_chat_message(&proposal_cookie, None)
        .await
        .unwrap();
    let chat_message_data = governance_chat_test
        .get_message_account(&chat_message_cookie.address)
        .await;
    assert_eq!(chat_message_data, chat_message_cookie.account);
}