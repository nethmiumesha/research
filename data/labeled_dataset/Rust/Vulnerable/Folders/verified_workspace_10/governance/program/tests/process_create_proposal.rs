#![cfg(feature = "test-sbf")]
use {
    solana_program::{instruction::AccountMeta, pubkey::Pubkey},
    solana_program_test::*,
};
mod program_test;
use {
    program_test::*,
    solana_sdk::signature::Keypair,
    spl_governance::{
        error::GovernanceError,
        state::{enums::VoteThreshold, governance::SECURITY_DEPOSIT_BASE_LAMPORTS},
    },
    spl_governance_tools::account::AccountMaxSize,
};
#[tokio::test]
async fn test_create_community_proposal() {
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
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_cookie.account, proposal_account);
    let token_owner_record_account = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(1, token_owner_record_account.outstanding_proposal_count);
    let governance_account = governance_test
        .get_governance_account(&governance_cookie.address)
        .await;
    assert_eq!(1, governance_account.active_proposal_count);
}
#[tokio::test]
async fn test_create_multiple_proposals() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let community_token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &community_token_owner_record_cookie)
        .await
        .unwrap();
    let council_token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let community_proposal_cookie = governance_test
        .with_proposal(&community_token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let council_proposal_cookie = governance_test
        .with_proposal(&council_token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let community_proposal_account = governance_test
        .get_proposal_account(&community_proposal_cookie.address)
        .await;
    assert_eq!(
        community_proposal_cookie.account,
        community_proposal_account
    );
    let council_proposal_account = governance_test
        .get_proposal_account(&council_proposal_cookie.address)
        .await;
    assert_eq!(council_proposal_cookie.account, council_proposal_account);
}
#[tokio::test]
async fn test_create_proposal_with_not_authorized_governance_authority_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    token_owner_record_cookie.governance_authority = Some(Keypair::new());
    let err = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenOwnerOrDelegateMustSign.into()
    );
}
#[tokio::test]
async fn test_create_proposal_with_governance_delegate_signer() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    governance_test
        .with_community_governance_delegate(&realm_cookie, &mut token_owner_record_cookie)
        .await;
    token_owner_record_cookie.governance_authority =
        Some(token_owner_record_cookie.clone_governance_delegate());
    let proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_cookie.account, proposal_account);
}
#[tokio::test]
async fn test_create_proposal_with_not_enough_community_tokens_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie1 = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie1)
        .await
        .unwrap();
    let token_amount = 4;
    let token_owner_record_cookie2 = governance_test
        .with_community_token_deposit_amount(&realm_cookie, token_amount)
        .await
        .unwrap();
    let err = governance_test
        .with_proposal(&token_owner_record_cookie2, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::NotEnoughTokensToCreateProposal.into());
}
#[tokio::test]
async fn test_create_proposal_with_not_enough_council_tokens_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_amount = 1;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit_amount(&realm_cookie, token_amount)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let err = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::NotEnoughTokensToCreateProposal.into());
}
#[tokio::test]
async fn test_create_proposal_with_owner_or_delegate_must_sign_error() {
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
    let council_token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let err = governance_test
        .with_proposal_using_instruction(&token_owner_record_cookie, &mut governance_cookie, |i| {
            i.accounts[3] =
                AccountMeta::new_readonly(council_token_owner_record_cookie.address, false);
        })
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenOwnerOrDelegateMustSign.into()
    );
}
#[tokio::test]
async fn test_create_proposal_with_invalid_governing_token_mint_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let mut token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    token_owner_record_cookie.account.governing_token_mint = Pubkey::new_unique();
    let err = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidGoverningTokenMint.into());
}
#[tokio::test]
async fn test_create_community_proposal_using_council_tokens() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let mut community_token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &community_token_owner_record_cookie)
        .await
        .unwrap();
    let council_token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    community_token_owner_record_cookie.address = council_token_owner_record_cookie.address;
    community_token_owner_record_cookie.token_owner = council_token_owner_record_cookie.token_owner;
    let proposal_cookie = governance_test
        .with_proposal(&community_token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(
        realm_cookie.account.community_mint,
        proposal_account.governing_token_mint
    );
    assert_eq!(
        council_token_owner_record_cookie.address,
        proposal_account.token_owner_record
    );
}
#[tokio::test]
async fn test_create_council_proposal_using_community_tokens() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let mut council_token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &council_token_owner_record_cookie)
        .await
        .unwrap();
    let community_token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    council_token_owner_record_cookie.address = community_token_owner_record_cookie.address;
    council_token_owner_record_cookie.token_owner = community_token_owner_record_cookie.token_owner;
    let proposal_cookie = governance_test
        .with_proposal(&council_token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(
        realm_cookie.account.config.council_mint.unwrap(),
        proposal_account.governing_token_mint
    );
    assert_eq!(
        community_token_owner_record_cookie.address,
        proposal_account.token_owner_record
    );
}
#[tokio::test]
async fn test_create_proposal_with_disabled_council_vote_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.council_vote_threshold = VoteThreshold::Disabled;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let err = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenMintNotAllowedToVote.into()
    );
}
#[tokio::test]
async fn test_create_proposal_with_disabled_community_vote_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.community_vote_threshold = VoteThreshold::Disabled;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let err = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenMintNotAllowedToVote.into()
    );
}
#[tokio::test]
async fn test_create_proposal_with_invalid_realm_config_account_address_error() {
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
    let realm_config_address = Pubkey::new_unique();
    let err = governance_test
        .with_proposal_using_instruction(&token_owner_record_cookie, &mut governance_cookie, |i| {
            i.accounts[8].pubkey = realm_config_address;
        })
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidRealmConfigAddress.into());
}
#[tokio::test]
async fn test_create_proposal_with_community_disabled_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_amount = u64::MAX;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit_amount(&realm_cookie, token_amount)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.min_community_weight_to_create_proposal = u64::MAX;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let err = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::VoterWeightThresholdDisabled.into());
}
#[tokio::test]
async fn test_create_proposal_with_security_deposit() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.deposit_exempt_proposal_count = 0;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_deposit_account = governance_test
        .get_proposal_deposit_account(&proposal_cookie.proposal_deposit.address)
        .await;
    assert_eq!(
        proposal_cookie.proposal_deposit.account,
        proposal_deposit_account
    );
    let proposal_deposit_account_info = governance_test
        .bench
        .get_account(&proposal_cookie.proposal_deposit.address)
        .await
        .unwrap();
    let expected_lamports = governance_test
        .bench
        .rent
        .minimum_balance(proposal_deposit_account.get_max_size().unwrap())
        + SECURITY_DEPOSIT_BASE_LAMPORTS;
    assert_eq!(expected_lamports, proposal_deposit_account_info.lamports);
}
#[tokio::test]
async fn test_create_multiple_proposals_with_security_deposits() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.deposit_exempt_proposal_count = 1;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_cookie1 = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_cookie2 = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_cookie3 = governance_test
        .with_proposal(&token_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let proposal_deposit_account_info1 = governance_test
        .bench
        .get_account(&proposal_cookie1.proposal_deposit.address)
        .await;
    assert_eq!(None, proposal_deposit_account_info1);
    let proposal_deposit_account2 = governance_test
        .get_proposal_deposit_account(&proposal_cookie2.proposal_deposit.address)
        .await;
    assert_eq!(
        proposal_cookie2.proposal_deposit.account,
        proposal_deposit_account2
    );
    let proposal_deposit_account_info2 = governance_test
        .bench
        .get_account(&proposal_cookie2.proposal_deposit.address)
        .await
        .unwrap();
    let expected_lamports = governance_test
        .bench
        .rent
        .minimum_balance(proposal_deposit_account2.get_max_size().unwrap())
        + SECURITY_DEPOSIT_BASE_LAMPORTS;
    assert_eq!(expected_lamports, proposal_deposit_account_info2.lamports);
    let proposal_deposit_account3 = governance_test
        .get_proposal_deposit_account(&proposal_cookie3.proposal_deposit.address)
        .await;
    assert_eq!(
        proposal_cookie3.proposal_deposit.account,
        proposal_deposit_account3
    );
    let proposal_deposit_account_info3 = governance_test
        .bench
        .get_account(&proposal_cookie3.proposal_deposit.address)
        .await
        .unwrap();
    let expected_lamports = governance_test
        .bench
        .rent
        .minimum_balance(proposal_deposit_account3.get_max_size().unwrap())
        + 2 * SECURITY_DEPOSIT_BASE_LAMPORTS;
    assert_eq!(expected_lamports, proposal_deposit_account_info3.lamports);
}