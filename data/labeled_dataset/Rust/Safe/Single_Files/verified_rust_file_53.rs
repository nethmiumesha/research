#![cfg(feature = "test-sbf")]
use {solana_program::pubkey::Pubkey, solana_program_test::*};
mod program_test;
use {
    crate::program_test::args::RealmSetupArgs,
    program_test::*,
    solana_sdk::signature::{Keypair, Signer},
    spl_governance::{
        error::GovernanceError,
        state::{realm::get_governing_token_holding_address, realm_config::GoverningTokenType},
    },
    spl_governance_test_sdk::tools::{clone_keypair, NopOverride},
};
#[tokio::test]
async fn test_revoke_community_tokens() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_config_args = RealmSetupArgs::default();
    realm_config_args.community_token_config_args.token_type = GoverningTokenType::Membership;
    let realm_cookie = governance_test
        .with_realm_using_args(&realm_config_args)
        .await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .revoke_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(token_owner_record.governing_token_deposit_amount, 0);
    let holding_account = governance_test
        .get_token_account(&realm_cookie.community_token_holding_account)
        .await;
    assert_eq!(holding_account.amount, 0);
}
#[tokio::test]
async fn test_revoke_council_tokens() {
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
    governance_test
        .revoke_council_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(token_owner_record.governing_token_deposit_amount, 0);
    let holding_account = governance_test
        .get_token_account(&realm_cookie.council_token_holding_account.unwrap())
        .await;
    assert_eq!(holding_account.amount, 0);
}
#[tokio::test]
async fn test_revoke_own_council_tokens() {
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
    governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            &token_owner_record_cookie.token_owner,
            token_owner_record_cookie
                .account
                .governing_token_deposit_amount,
            NopOverride,
            None,
        )
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(token_owner_record.governing_token_deposit_amount, 0);
}
#[tokio::test]
async fn test_revoke_own_council_tokens_with_owner_must_sign_error() {
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
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            &token_owner_record_cookie.token_owner,
            token_owner_record_cookie
                .account
                .governing_token_deposit_amount,
            |i| i.accounts[4].is_signer = false,
            Some(&[]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::GoverningTokenOwnerMustSign.into());
}
#[tokio::test]
async fn test_revoke_community_tokens_with_cannot_revoke_liquid_token_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let err = governance_test
        .revoke_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::CannotRevokeGoverningTokens.into());
}
#[tokio::test]
async fn test_revoke_community_tokens_with_cannot_revoke_dormant_token_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut realm_config_args = RealmSetupArgs::default();
    realm_config_args.community_token_config_args.token_type = GoverningTokenType::Dormant;
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_config_args)
        .await
        .unwrap();
    let err = governance_test
        .revoke_community_tokens(&realm_cookie, &token_owner_record_cookie)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::CannotRevokeGoverningTokens.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_mint_authority_must_sign_error() {
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
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| i.accounts[4].is_signer = false,
            Some(&[]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::MintAuthorityMustSign.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_invalid_revoke_authority_error() {
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
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            &Keypair::new(),
            1,
            NopOverride,
            None,
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidMintAuthority.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_invalid_token_holding_error() {
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
    let governing_token_holding_address = get_governing_token_holding_address(
        &governance_test.program_id,
        &realm_cookie.address,
        &realm_cookie.account.community_mint,
    );
    let err = governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| i.accounts[1].pubkey = governing_token_holding_address,
            None,
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
async fn test_revoke_council_tokens_with_other_realm_config_account_error() {
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
    let realm_cookie2 = governance_test.with_realm().await;
    let err = governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| i.accounts[5].pubkey = realm_cookie2.realm_config.address,
            None,
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidRealmConfigForRealm.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_invalid_realm_config_account_address_error() {
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
    let realm_config_address = Pubkey::new_unique();
    let err = governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| i.accounts[5].pubkey = realm_config_address,
            None,
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidRealmConfigAddress.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_token_owner_record_for_different_mint_error() {
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
    let token_owner_record_cookie2 = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let err = governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| i.accounts[2].pubkey = token_owner_record_cookie2.address,
            None,
        )
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidGoverningMintForTokenOwnerRecord.into()
    );
}
#[tokio::test]
async fn test_revoke_council_tokens_with_too_large_amount_error() {
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
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            200,
            NopOverride,
            None,
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidRevokeAmount.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_partial_revoke_amount() {
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
    governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            5,
            NopOverride,
            None,
        )
        .await
        .unwrap();
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(token_owner_record.governing_token_deposit_amount, 95);
}
#[tokio::test]
async fn test_revoke_council_tokens_with_community_mint_error() {
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
    let governing_token_mint = realm_cookie.account.community_mint;
    let governing_token_mint_authority = clone_keypair(&realm_cookie.community_mint_authority);
    let governing_token_holding_address = get_governing_token_holding_address(
        &governance_test.program_id,
        &realm_cookie.address,
        &governing_token_mint,
    );
    let err = governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| {
                i.accounts[1].pubkey = governing_token_holding_address;
                i.accounts[3].pubkey = governing_token_mint;
                i.accounts[4].pubkey = governing_token_mint_authority.pubkey();
            },
            Some(&[&governing_token_mint_authority]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::CannotRevokeGoverningTokens.into());
}
#[tokio::test]
async fn test_revoke_council_tokens_with_not_matching_mint_and_authority_error() {
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
    let governing_token_mint = realm_cookie.account.community_mint;
    let governing_token_mint_authority = clone_keypair(&realm_cookie.community_mint_authority);
    let err = governance_test
        .revoke_governing_tokens_using_instruction(
            &realm_cookie,
            &token_owner_record_cookie,
            &realm_cookie.account.config.council_mint.unwrap(),
            realm_cookie.council_mint_authority.as_ref().unwrap(),
            1,
            |i| {
                i.accounts[3].pubkey = governing_token_mint;
                i.accounts[4].pubkey = governing_token_mint_authority.pubkey();
            },
            Some(&[&governing_token_mint_authority]),
        )
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::InvalidGoverningTokenHoldingAccount.into()
    );
}