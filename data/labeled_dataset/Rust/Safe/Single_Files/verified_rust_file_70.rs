#![cfg(feature = "test-sbf")]
use solana_program_test::*;
mod program_test;
use {
    program_test::{args::*, *},
    spl_governance::{error::GovernanceError, state::enums::ProposalState},
};
#[tokio::test]
async fn test_cast_vote_with_community_max_voter_weight_addin() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record(&mut token_owner_record_cookie)
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
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Voting)
}
#[tokio::test]
async fn test_cast_vote_with_council_max_voter_weight_addin() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COUNCIL_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record(&mut token_owner_record_cookie)
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
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Voting)
}
#[tokio::test]
async fn test_tip_vote_with_max_voter_weight_addin() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit_amount(&realm_cookie, 180)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record(&mut token_owner_record_cookie)
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
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Succeeded);
    assert_eq!(proposal_account.max_vote_weight, Some(200));
}
#[tokio::test]
async fn test_tip_vote_with_max_voter_weight_addin_and_max_below_total_cast_votes() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record_impl(&mut token_owner_record_cookie, 50, None)
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
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Succeeded);
    assert_eq!(proposal_account.max_vote_weight, Some(100));
}
#[tokio::test]
async fn test_finalize_vote_with_max_voter_weight_addin() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record(&mut token_owner_record_cookie)
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
    let max_voter_weight_record_cookie = governance_test
        .with_max_voter_weight_addin_record_impl(&mut token_owner_record_cookie, 120, None)
        .await
        .unwrap();
    governance_test
        .advance_clock_past_voting_time(&governance_cookie)
        .await;
    governance_test
        .finalize_vote(
            &realm_cookie,
            &proposal_cookie,
            Some(max_voter_weight_record_cookie),
        )
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Succeeded);
    assert_eq!(proposal_account.max_vote_weight, Some(120));
}
#[tokio::test]
async fn test_finalize_vote_with_max_voter_weight_addin_and_max_below_total_cast_votes() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record(&mut token_owner_record_cookie)
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
    let max_voter_weight_record_cookie = governance_test
        .with_max_voter_weight_addin_record_impl(&mut token_owner_record_cookie, 50, None)
        .await
        .unwrap();
    governance_test
        .advance_clock_past_voting_time(&governance_cookie)
        .await;
    governance_test
        .finalize_vote(
            &realm_cookie,
            &proposal_cookie,
            Some(max_voter_weight_record_cookie),
        )
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Succeeded);
    assert_eq!(proposal_account.max_vote_weight, Some(100));
}
#[tokio::test]
async fn test_cast_vote_with_max_voter_weight_addin_and_expired_record_error() {
    let mut governance_test = GovernanceProgramTest::start_with_max_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_MAX_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .with_max_voter_weight_addin_record_impl(&mut token_owner_record_cookie, 200, Some(1))
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
    governance_test.advance_clock().await;
    let err = governance_test
        .with_cast_yes_no_vote(&proposal_cookie, &token_owner_record_cookie, YesNoVote::Yes)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::MaxVoterWeightRecordExpired.into());
}