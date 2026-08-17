#![cfg(feature = "test-sbf")]
mod program_test;
use {
    crate::program_test::args::RealmSetupArgs,
    program_test::*,
    solana_program_test::*,
    solana_sdk::signature::Keypair,
    spl_governance::{error::GovernanceError, state::enums::VoteThreshold},
    spl_governance_tools::error::GovernanceToolsError,
};
#[tokio::test]
async fn test_create_governance() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let governance_account = governance_test
        .get_governance_account(&governance_cookie.address)
        .await;
    assert_eq!(governance_cookie.account, governance_account);
}
#[tokio::test]
async fn test_create_governance_with_invalid_realm_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    realm_cookie.address = governance_cookie.address;
    let err = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceToolsError::InvalidAccountType.into());
}
#[tokio::test]
async fn test_create_governance_with_invalid_config_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut config = governance_test.get_default_governance_config();
    config.community_vote_threshold = VoteThreshold::YesVotePercentage(0);
    let err = governance_test
        .with_governance_using_config(&realm_cookie, &token_owner_record_cookie, &config)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidVoteThresholdPercentage.into());
    let mut config = governance_test.get_default_governance_config();
    config.community_vote_threshold = VoteThreshold::YesVotePercentage(101);
    let err = governance_test
        .with_governance_using_config(&realm_cookie, &token_owner_record_cookie, &config)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidVoteThresholdPercentage.into());
}
#[tokio::test]
async fn test_create_governance_with_not_enough_community_tokens_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_amount = 4;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit_amount(&realm_cookie, token_amount)
        .await
        .unwrap();
    let err = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::NotEnoughTokensToCreateGovernance.into()
    );
}
#[tokio::test]
async fn test_create_governance_with_not_enough_council_tokens_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_amount: u64 = 0;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit_amount(&realm_cookie, token_amount)
        .await
        .unwrap();
    let err = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::NotEnoughTokensToCreateGovernance.into()
    );
}
#[tokio::test]
async fn test_create_governance_using_realm_authority() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let config = governance_test.get_default_governance_config();
    let realm_authority = realm_cookie.realm_authority.as_ref().unwrap();
    let governance_cookie = governance_test
        .with_governance_impl(&realm_cookie, None, realm_authority, None, &config, None)
        .await
        .unwrap();
    let governance_account = governance_test
        .get_governance_account(&governance_cookie.address)
        .await;
    assert_eq!(governance_cookie.account, governance_account);
}
#[tokio::test]
async fn test_create_governance_using_realm_authority_with_authority_must_sign_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let config = governance_test.get_default_governance_config();
    let realm_authority = realm_cookie.realm_authority.as_ref().unwrap();
    let err = governance_test
        .with_governance_impl(
            &realm_cookie,
            None,
            realm_authority,
            None,
            &config,
            Some(&[]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::RealmAuthorityMustSign.into());
}
#[tokio::test]
async fn test_create_governance_using_realm_authority_with_wrong_authority_sign_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let config = governance_test.get_default_governance_config();
    let authority = Keypair::new();
    let err = governance_test
        .with_governance_impl(
            &realm_cookie,
            Some(&token_owner_record_cookie.address),
            &authority,
            None,
            &config,
            Some(&[&authority]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenOwnerOrDelegateMustSign.into()
    );
}
#[tokio::test]
async fn test_create_governance_with_community_disabled_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_config_args = RealmSetupArgs {
        min_community_weight_to_create_governance: u64::MAX,
        ..Default::default()
    };
    let realm_cookie = governance_test
        .with_realm_using_args(&realm_config_args)
        .await;
    let token_amount = u64::MAX;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit_amount(&realm_cookie, token_amount)
        .await
        .unwrap();
    let err = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::VoterWeightThresholdDisabled.into());
}