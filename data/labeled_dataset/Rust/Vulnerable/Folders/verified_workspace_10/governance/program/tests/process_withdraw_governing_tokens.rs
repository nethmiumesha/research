#![cfg(feature = "test-sbf")]
use {
    solana_program::{instruction::AccountMeta, pubkey::Pubkey},
    solana_program_test::*,
};
mod program_test;
use {
    crate::program_test::args::RealmSetupArgs,
    program_test::*,
    solana_sdk::signature::Signer,
    spl_governance::{
        error::GovernanceError,
        instruction::withdraw_governing_tokens,
        state::{
            realm_config::GoverningTokenType, token_owner_record::get_token_owner_record_address,
        },
    },
};
#[tokio::test]
async fn test_withdraw_community_tokens() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(0, token_owner_record.governing_token_deposit_amount);
    let holding_account = governance_test
        .get_token_account(&realm_cookie.community_token_holding_account)
        .await;
    assert_eq!(0, holding_account.amount);
    let source_account = governance_test
        .get_token_account(&token_owner_record_cookie.token_source)
        .await;
    assert_eq!(
        token_owner_record_cookie.token_source_amount,
        source_account.amount
    );
}
#[tokio::test]
async fn test_withdraw_council_tokens() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .withdraw_council_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(0, token_owner_record.governing_token_deposit_amount);
    let holding_account = governance_test
        .get_token_account(&realm_cookie.council_token_holding_account.unwrap())
        .await;
    assert_eq!(0, holding_account.amount);
    let source_account = governance_test
        .get_token_account(&token_owner_record_cookie.token_source)
        .await;
    assert_eq!(
        token_owner_record_cookie.token_source_amount,
        source_account.amount
    );
}
#[tokio::test]
async fn test_withdraw_community_tokens_with_owner_must_sign_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let hacker_token_destination = Pubkey::new_unique();
    let mut withdraw_ix = withdraw_governing_tokens(
        &governance_test.program_id,
        &realm_cookie.address,
        &hacker_token_destination,
        &token_owner_record_cookie.token_owner.pubkey(),
        &realm_cookie.account.community_mint,
    );
    withdraw_ix.accounts[3] =
        AccountMeta::new_readonly(token_owner_record_cookie.token_owner.pubkey(), false);
    let err = governance_test
        .bench
        .process_transaction(&[withdraw_ix], None)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::GoverningTokenOwnerMustSign.into());
}
#[tokio::test]
async fn test_withdraw_community_tokens_with_token_owner_record_address_mismatch_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let vote_record_address = get_token_owner_record_address(
        &governance_test.program_id,
        &realm_cookie.address,
        &realm_cookie.account.community_mint,
        &token_owner_record_cookie.token_owner.pubkey(),
    );
    let hacker_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut withdraw_ix = withdraw_governing_tokens(
        &governance_test.program_id,
        &realm_cookie.address,
        &hacker_record_cookie.token_source,
        &hacker_record_cookie.token_owner.pubkey(),
        &realm_cookie.account.community_mint,
    );
    withdraw_ix.accounts[4] = AccountMeta::new(vote_record_address, false);
    let err = governance_test
        .bench
        .process_transaction(&[withdraw_ix], Some(&[&hacker_record_cookie.token_owner]))
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidTokenOwnerRecordAccountAddress.into()
    );
}
#[tokio::test]
async fn test_withdraw_governing_tokens_with_unrelinquished_votes_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    let err = governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::AllVotesMustBeRelinquishedToWithdrawGoverningTokens.into()
    );
}
#[tokio::test]
async fn test_withdraw_governing_tokens_after_relinquishing_vote() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .unwrap();
    governance_test
        .relinquish_vote(&proposal_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let source_account = governance_test
        .get_token_account(&token_owner_record_cookie.token_source)
        .await;
    assert_eq!(
        token_owner_record_cookie.token_source_amount,
        source_account.amount
    );
}
#[tokio::test]
async fn test_withdraw_tokens_with_malicious_holding_account_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let realm_token_account_cookie = governance_test
        .bench
        .with_token_account(
            &realm_cookie.account.community_mint,
            &realm_cookie.address,
            &realm_cookie.community_mint_authority,
            200,
        )
        .await;
    let mut withdraw_ix = withdraw_governing_tokens(
        &governance_test.program_id,
        &realm_cookie.address,
        &token_owner_record_cookie.token_source,
        &token_owner_record_cookie.token_owner.pubkey(),
        &realm_cookie.account.community_mint,
    );
    withdraw_ix.accounts[1].pubkey = realm_token_account_cookie.address;
    let err = governance_test
        .bench
        .process_transaction(
            &[withdraw_ix],
            Some(&[&token_owner_record_cookie.token_owner]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidGoverningTokenHoldingAccount.into()
    );
}
#[tokio::test]
async fn test_withdraw_governing_tokens_with_outstanding_proposals_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_signed_off_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let err = governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::AllProposalsMustBeFinalisedToWithdrawGoverningTokens.into()
    );
}
#[tokio::test]
async fn test_withdraw_governing_tokens_after_proposal_cancelled() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .cancel_proposal(&proposal_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let source_account = governance_test
        .get_token_account(&token_owner_record_cookie.token_source)
        .await;
    assert_eq!(
        token_owner_record_cookie.token_source_amount,
        source_account.amount
    );
}
#[tokio::test]
async fn test_withdraw_council_tokens_with_cannot_withdraw_membership_tokens_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_config_args = RealmSetupArgs::default();
    realm_config_args.council_token_config_args.token_type = GoverningTokenType::Membership;
    let realm_cookie = governance_test
        .with_realm_using_args(&realm_config_args)
        .await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let err = governance_test
        .withdraw_council_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::CannotWithdrawMembershipTokens.into());
}
#[tokio::test]
async fn test_withdraw_dormant_community_tokens() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut realm_setup_args = RealmSetupArgs::default();
    realm_setup_args.community_token_config_args.token_type = GoverningTokenType::Dormant;
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(0, token_owner_record.governing_token_deposit_amount);
}
#[tokio::test]
async fn test_withdraw_governing_tokens_with_token_owner_record_lock_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let token_owner_record_lock_authority_cookie = governance_test
        .with_community_token_owner_record_lock_authority(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_token_owner_record_lock(
            &token_owner_record_cookie,
            &token_owner_record_lock_authority_cookie,
        )
        .await
        .unwrap();
    let err = governance_test
        .withdraw_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::TokenOwnerRecordLocked.into());
}