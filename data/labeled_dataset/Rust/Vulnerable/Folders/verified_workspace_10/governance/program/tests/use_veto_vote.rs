#![cfg(feature = "test-sbf")]
mod program_test;
use {
    crate::program_test::args::{PluginSetupArgs, RealmSetupArgs},
    program_test::*,
    solana_program::instruction::AccountMeta,
    solana_program_test::tokio,
    spl_governance::{
        error::GovernanceError,
        state::{
            enums::{ProposalState, VoteThreshold},
            vote_record::Vote,
        },
    },
    spl_governance_test_sdk::tools::clone_keypair,
};
#[tokio::test]
async fn test_cast_council_veto_vote() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test.mint_council_tokens(&realm_cookie, 20).await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let clock = governance_test.bench.get_clock().await;
    let vote_record_cookie = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let vote_record_account = governance_test
        .get_vote_record_account(&vote_record_cookie.address)
        .await;
    assert_eq!(vote_record_cookie.account, vote_record_account);
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(
        token_owner_record_cookie
            .account
            .governing_token_deposit_amount,
        proposal_account.veto_vote_weight
    );
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
    assert_eq!(
        proposal_account.voting_completed_at,
        Some(clock.unix_timestamp)
    );
    assert_eq!(Some(120), proposal_account.max_vote_weight);
    assert_eq!(
        Some(governance_cookie.account.config.council_veto_vote_threshold),
        proposal_account.vote_threshold
    );
    let token_owner_record = governance_test
        .get_token_owner_record_account(&token_owner_record_cookie.address)
        .await;
    assert_eq!(1, token_owner_record.unrelinquished_votes_count);
}
#[tokio::test]
async fn test_cast_community_veto_vote() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .mint_community_tokens(&realm_cookie, 20)
        .await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let vote_record_cookie = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let vote_record_account = governance_test
        .get_vote_record_account(&vote_record_cookie.address)
        .await;
    assert_eq!(vote_record_cookie.account, vote_record_account);
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(
        token_owner_record_cookie
            .account
            .governing_token_deposit_amount,
        proposal_account.veto_vote_weight
    );
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
    assert_eq!(Some(120), proposal_account.max_vote_weight);
    assert_eq!(
        Some(
            governance_cookie
                .account
                .config
                .community_veto_vote_threshold
        ),
        proposal_account.vote_threshold
    );
}
#[tokio::test]
async fn test_cast_community_veto_vote_with_community_veto_disabled_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.community_veto_vote_threshold = VoteThreshold::Disabled;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let err = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenMintNotAllowedToVote.into()
    );
}
#[tokio::test]
async fn test_cast_veto_vote_with_invalid_voting_mint_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let err = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidGoverningMintForProposal.into());
}
#[tokio::test]
async fn test_cast_veto_vote_with_council_veto_vote_disabled_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.council_veto_vote_threshold = VoteThreshold::Disabled;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let err = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .err()
        .unwrap();
    assert_eq!(
        err,
        GovernanceError::GoverningTokenMintNotAllowedToVote.into()
    );
}
#[tokio::test]
async fn test_cast_veto_vote_without_tipping() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .mint_council_tokens(&realm_cookie, 101)
        .await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let vote_record_cookie = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let vote_record_account = governance_test
        .get_vote_record_account(&vote_record_cookie.address)
        .await;
    assert_eq!(vote_record_cookie.account, vote_record_account);
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(
        token_owner_record_cookie
            .account
            .governing_token_deposit_amount,
        proposal_account.veto_vote_weight
    );
    assert_eq!(proposal_account.state, ProposalState::Voting);
}
#[tokio::test]
async fn test_cast_multiple_veto_votes_for_partially_approved_proposal() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let token_owner_record_cookie2 = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test.mint_council_tokens(&realm_cookie, 10).await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .mint_community_tokens(&realm_cookie, 100)
        .await;
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(
            &proposal_cookie,
            &proposal_owner_record_cookie,
            YesNoVote::Yes,
        )
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie2, Vote::Veto)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(200, proposal_account.veto_vote_weight);
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
}
#[tokio::test]
async fn test_cast_veto_vote_with_no_council_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let mut realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.council_veto_vote_threshold = VoteThreshold::Disabled;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let realm_setup_args = RealmSetupArgs {
        use_council_mint: false,
        ..Default::default()
    };
    governance_test
        .set_realm_config(&mut realm_cookie, &realm_setup_args)
        .await
        .unwrap();
    let err = governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidGoverningTokenMint.into());
}
#[tokio::test]
async fn test_relinquish_veto_vote() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .mint_council_tokens(&realm_cookie, 101)
        .await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    governance_test
        .relinquish_vote(&proposal_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(0, proposal_account.veto_vote_weight);
    assert_eq!(proposal_account.state, ProposalState::Voting);
}
#[tokio::test]
async fn test_relinquish_veto_vote_with_vote_record_for_different_voting_mint_error() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let council_token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .mint_council_tokens(&realm_cookie, 110)
        .await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &council_token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(
            &proposal_cookie,
            &council_token_owner_record_cookie,
            Vote::Veto,
        )
        .await
        .unwrap();
    let community_token_owner_record_cookie = governance_test
        .with_community_token_deposit_by_owner(
            &realm_cookie,
            100,
            clone_keypair(&council_token_owner_record_cookie.token_owner),
        )
        .await
        .unwrap();
    governance_test
        .mint_community_tokens(&realm_cookie, 150)
        .await;
    let community_vote_record_cookie = governance_test
        .with_cast_yes_no_vote(
            &proposal_cookie,
            &community_token_owner_record_cookie,
            YesNoVote::Yes,
        )
        .await
        .unwrap();
    let err = governance_test
        .relinquish_vote_using_instruction(
            &proposal_cookie,
            &council_token_owner_record_cookie,
            |i| {
                i.accounts[4] = AccountMeta::new(community_vote_record_cookie.address, false)
            },
        )
        .await
        .err()
        .unwrap();
    assert_eq!(err, GovernanceError::InvalidGoverningMintForProposal.into());
}
#[tokio::test]
async fn test_cast_veto_vote_with_council_only_allowed_to_veto() {
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
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
}
#[tokio::test]
async fn test_cast_yes_and_veto_votes_with_yes_as_winning_vote() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test
        .mint_council_tokens(&realm_cookie, 110)
        .await;
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    governance_test
        .with_cast_yes_no_vote(
            &proposal_cookie,
            &proposal_owner_record_cookie,
            YesNoVote::Yes,
        )
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(100, proposal_account.veto_vote_weight);
    assert_eq!(proposal_account.state, ProposalState::Succeeded);
}
#[tokio::test]
async fn test_veto_vote_with_community_voter_weight_addin() {
    let mut governance_test = GovernanceProgramTest::start_with_voter_weight_addin().await;
    let realm_cookie = governance_test
        .with_realm_using_addins(PluginSetupArgs::COMMUNITY_VOTER_WEIGHT)
        .await;
    let mut token_owner_record_cookie = governance_test
        .with_community_token_owner_record(&realm_cookie)
        .await;
    governance_test
        .with_voter_weight_addin_record(&mut token_owner_record_cookie)
        .await
        .unwrap();
    let mut governance_cookie = governance_test
        .with_governance(&realm_cookie, &token_owner_record_cookie)
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
}
#[tokio::test]
async fn test_veto_vote_with_community_max_voter_weight_addin() {
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
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.community_veto_vote_threshold = VoteThreshold::YesVotePercentage(50);
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
}
#[tokio::test]
async fn test_veto_vote_with_community_max_voter_weight_addin_and_veto_not_tipped() {
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
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.community_veto_vote_threshold = VoteThreshold::YesVotePercentage(51);
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Voting);
}
#[tokio::test]
async fn test_cast_council_veto_vote_within_cool_off_time() {
    let mut governance_test = GovernanceProgramTest::start_new().await;
    let realm_cookie = governance_test.with_realm().await;
    let token_owner_record_cookie = governance_test
        .with_council_token_deposit(&realm_cookie)
        .await
        .unwrap();
    governance_test.mint_council_tokens(&realm_cookie, 20).await;
    let mut governance_config = governance_test.get_default_governance_config();
    governance_config.voting_cool_off_time = 50;
    let mut governance_cookie = governance_test
        .with_governance_using_config(
            &realm_cookie,
            &token_owner_record_cookie,
            &governance_config,
        )
        .await
        .unwrap();
    let proposal_owner_record_cookie = governance_test
        .with_community_token_deposit(&realm_cookie)
        .await
        .unwrap();
    let proposal_cookie = governance_test
        .with_signed_off_proposal(&proposal_owner_record_cookie, &mut governance_cookie)
        .await
        .unwrap();
    let clock = governance_test.bench.get_clock().await;
    governance_test
        .advance_clock_past_timestamp(
            clock.unix_timestamp + governance_cookie.account.config.voting_base_time as i64,
        )
        .await;
    governance_test
        .with_cast_vote(&proposal_cookie, &token_owner_record_cookie, Vote::Veto)
        .await
        .unwrap();
    let proposal_account = governance_test
        .get_proposal_account(&proposal_cookie.address)
        .await;
    assert_eq!(proposal_account.state, ProposalState::Vetoed);
}