#![cfg(feature = "test-sbf")]
use {solana_program::pubkey::Pubkey, solana_program_test::*, solana_sdk::signer::Signer};
mod program_test;
use {
    crate::program_test::args::RealmSetupArgs,
    program_test::*,
    spl_governance::{
        error::GovernanceError,
        state::{realm::GoverningTokenConfigAccountArgs, realm_config::GoverningTokenType},
    },
};
#[tokio::test]
async fn test_set_realm_config() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs::default();
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let realm_account = governance_test
        .get_realm_account(&realm_cookie.address)
        .await;
    assert_eq!(realm_cookie.account, realm_account);
}
#[tokio::test]
async fn test_set_realm_config_with_authority_must_sign_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs::default();
    let err = governance_test
        .set_realm_config_using_instruction(
            &mut realm_cookie,
            &realm_setup_args,
            |i| i.accounts[1].is_signer = false,
            Some(&[]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::RealmAuthorityMustSign.into());
}
#[tokio::test]
async fn test_set_realm_config_with_no_authority_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs::default();
    governance_test
        .set_realm_authority(&realm_cookie, None)
        .await
        .unwrap();
    let err = governance_test
        .set_realm_config_using_instruction(
            &mut realm_cookie,
            &realm_setup_args,
            |i| i.accounts[1].is_signer = false,
            Some(&[]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::RealmHasNoAuthority.into());
}
#[tokio::test]
async fn test_set_realm_config_with_invalid_authority_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs::default();
    let realm_cookie2 = governance_test.with_realm().await;
    realm_cookie.realm_authority = realm_cookie2.realm_authority;
    let err = governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidAuthorityForRealm.into());
}
#[tokio::test]
async fn test_set_realm_config_with_remove_council() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs {
        use_council_mint: false,
        ..Default::default()
    };
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let realm_account = governance_test
        .get_realm_account(&realm_cookie.address)
        .await;
    assert_eq!(realm_cookie.account, realm_account);
    assert_eq!(None, realm_account.config.council_mint);
}
#[tokio::test]
async fn test_set_realm_config_with_council_change_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs::default();
    realm_cookie.account.config.council_mint = serde::__private::Some(Pubkey::new_unique());
    let err = governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::RealmCouncilMintChangeIsNotSupported.into()
    );
}
#[tokio::test]
async fn test_set_realm_config_with_council_restore_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let mut realm_setup_args = RealmSetupArgs {
        use_council_mint: false,
        ..Default::default()
    };
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    realm_setup_args.use_council_mint = true;
    realm_cookie.account.config.council_mint = serde::__private::Some(Pubkey::new_unique());
    let err = governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::RealmCouncilMintChangeIsNotSupported.into()
    );
}
#[tokio::test]
async fn test_set_realm_config_with_liquid_community_token_cannot_be_changed_to_memebership_error()
{
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let mut realm_setup_args = RealmSetupArgs::default();
    realm_setup_args.community_token_config_args.token_type = GoverningTokenType::Membership;
    let err = governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::CannotChangeCommunityTokenTypeToMembership.into()
    );
}
#[tokio::test]
async fn test_set_realm_config_for_community_token_config() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs {
        community_token_config_args: GoverningTokenConfigAccountArgs {
            voter_weight_addin: Some(Pubkey::new_unique()),
            max_voter_weight_addin: Some(Pubkey::new_unique()),
            token_type: GoverningTokenType::Dormant,
        },
        ..Default::default()
    };
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let realm_config_account = governance_test
        .get_realm_config_account(&realm_cookie.realm_config.address)
        .await;
    assert_eq!(
        realm_config_account.community_token_config.token_type,
        GoverningTokenType::Dormant
    );
    assert_eq!(
        realm_config_account
            .community_token_config
            .voter_weight_addin,
        realm_setup_args
            .community_token_config_args
            .voter_weight_addin
    );
    assert_eq!(
        realm_config_account
            .community_token_config
            .max_voter_weight_addin,
        realm_setup_args
            .community_token_config_args
            .max_voter_weight_addin
    );
}
#[tokio::test]
async fn test_set_realm_config_for_council_token_config() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs {
        council_token_config_args: GoverningTokenConfigAccountArgs {
            voter_weight_addin: Some(Pubkey::new_unique()),
            max_voter_weight_addin: Some(Pubkey::new_unique()),
            token_type: GoverningTokenType::Membership,
        },
        ..Default::default()
    };
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let realm_config_account = governance_test
        .get_realm_config_account(&realm_cookie.realm_config.address)
        .await;
    assert_eq!(
        realm_config_account.council_token_config.token_type,
        GoverningTokenType::Membership
    );
    assert_eq!(
        realm_config_account.council_token_config.voter_weight_addin,
        realm_setup_args
            .council_token_config_args
            .voter_weight_addin
    );
    assert_eq!(
        realm_config_account
            .council_token_config
            .max_voter_weight_addin,
        realm_setup_args
            .council_token_config_args
            .max_voter_weight_addin
    );
}
#[tokio::test]
async fn test_set_realm_config_without_existing_realm_config() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let realm_setup_args = RealmSetupArgs::default();
    governance_test.remove_realm_config_account(&realm_cookie.realm_config.address);
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let realm_account = governance_test
        .get_realm_account(&realm_cookie.address)
        .await;
    assert_eq!(realm_cookie.account, realm_account);
}
#[tokio::test]
async fn test_set_realm_config_with_token_owner_record_lock_authorities() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let community_token_owner_record_lock_authority_cookie = governance_test
        .with_community_token_owner_record_lock_authority(&realm_cookie)
        .await
        .unwrap();
    let council_token_owner_record_lock_authority_cookie = governance_test
        .with_council_token_owner_record_lock_authority(&realm_cookie)
        .await
        .unwrap();
    let realm_setup_args = RealmSetupArgs::default();
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let realm_config_account = governance_test
        .get_realm_config_account(&realm_cookie.realm_config.address)
        .await;
    assert_eq!(
        vec![community_token_owner_record_lock_authority_cookie
            .authority
            .pubkey()],
        realm_config_account.community_token_config.lock_authorities
    );
    assert_eq!(
        vec![council_token_owner_record_lock_authority_cookie
            .authority
            .pubkey()],
        realm_config_account.council_token_config.lock_authorities
    );
}