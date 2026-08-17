use {
    crate::{
        addins::max_voter_weight::{
            assert_is_valid_max_voter_weight,
            get_max_voter_weight_record_data_for_realm_and_governing_token_mint,
        },
        error::GovernanceError,
        state::{
            enums::{
                GovernanceAccountType, InstructionExecutionFlags, MintMaxVoterWeightSource,
                ProposalState, VoteThreshold, VoteTipping,
            },
            governance::GovernanceConfig,
            legacy::ProposalV1,
            proposal_transaction::ProposalTransactionV2,
            realm::RealmV2,
            realm_config::RealmConfigAccount,
            vote_record::{Vote, VoteKind},
        },
        tools::spl_token::get_spl_token_mint_supply,
        PROGRAM_AUTHORITY_SEED,
    },
    borsh::{io::Write, BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::{next_account_info, AccountInfo},
        clock::{Slot, UnixTimestamp},
        program_error::ProgramError,
        program_pack::IsInitialized,
        pubkey::Pubkey,
    },
    spl_governance_tools::account::{get_account_data, get_account_type, AccountMaxSize},
    std::{cmp::Ordering, slice::Iter},
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum OptionVoteResult {
    None,
    Succeeded,
    Defeated,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProposalOption {
    pub label: String,
    pub vote_weight: u64,
    pub vote_result: OptionVoteResult,
    pub transactions_executed_count: u16,
    pub transactions_count: u16,
    pub transactions_next_index: u16,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteType {
    SingleChoice,
    MultiChoice {
        #[allow(dead_code)]
        choice_type: MultiChoiceType,
        #[allow(dead_code)]
        min_voter_options: u8,
        #[allow(dead_code)]
        max_voter_options: u8,
        #[allow(dead_code)]
        max_winning_options: u8,
    },
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum MultiChoiceType {
    FullWeight,
    Weighted,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProposalV2 {
    pub account_type: GovernanceAccountType,
    pub governance: Pubkey,
    pub governing_token_mint: Pubkey,
    pub state: ProposalState,
    pub token_owner_record: Pubkey,
    pub signatories_count: u8,
    pub signatories_signed_off_count: u8,
    pub vote_type: VoteType,
    pub options: Vec<ProposalOption>,
    pub deny_vote_weight: Option<u64>,
    pub reserved1: u8,
    pub abstain_vote_weight: Option<u64>,
    pub start_voting_at: Option<UnixTimestamp>,
    pub draft_at: UnixTimestamp,
    pub signing_off_at: Option<UnixTimestamp>,
    pub voting_at: Option<UnixTimestamp>,
    pub voting_at_slot: Option<Slot>,
    pub voting_completed_at: Option<UnixTimestamp>,
    pub executing_at: Option<UnixTimestamp>,
    pub closed_at: Option<UnixTimestamp>,
    pub execution_flags: InstructionExecutionFlags,
    pub max_vote_weight: Option<u64>,
    pub max_voting_time: Option<u32>,
    pub vote_threshold: Option<VoteThreshold>,
    pub reserved: [u8; 64],
    pub name: String,
    pub description_link: String,
    pub veto_vote_weight: u64,
}
impl AccountMaxSize for ProposalV2 {
    fn get_max_size(&self) -> Option<usize> {
        let options_size: usize = self.options.iter().map(|o| o.label.len() + 19).sum();
        Some(self.name.len() + self.description_link.len() + options_size + 297)
    }
}
impl IsInitialized for ProposalV2 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::ProposalV2
    }
}
impl ProposalV2 {
    pub fn assert_can_edit_signatories(&self) -> Result<(), ProgramError> {
        self.assert_is_draft_state()
            .map_err(|_| GovernanceError::InvalidStateCannotEditSignatories.into())
    }
    pub fn assert_can_sign_off(&self) -> Result<(), ProgramError> {
        match self.state {
            ProposalState::Draft | ProposalState::SigningOff => Ok(()),
            ProposalState::Executing
            | ProposalState::ExecutingWithErrors
            | ProposalState::Completed
            | ProposalState::Cancelled
            | ProposalState::Voting
            | ProposalState::Succeeded
            | ProposalState::Defeated
            | ProposalState::Vetoed => Err(GovernanceError::InvalidStateCannotSignOff.into()),
        }
    }
    fn assert_is_voting_state(&self) -> Result<(), ProgramError> {
        if self.state != ProposalState::Voting {
            return Err(GovernanceError::InvalidProposalState.into());
        }
        Ok(())
    }
    fn assert_is_draft_state(&self) -> Result<(), ProgramError> {
        if self.state != ProposalState::Draft {
            return Err(GovernanceError::InvalidProposalState.into());
        }
        Ok(())
    }
    pub fn assert_is_final_state(&self) -> Result<(), ProgramError> {
        match self.state {
            ProposalState::Completed
            | ProposalState::Cancelled
            | ProposalState::Defeated
            | ProposalState::Vetoed => Ok(()),
            ProposalState::Executing
            | ProposalState::ExecutingWithErrors
            | ProposalState::SigningOff
            | ProposalState::Voting
            | ProposalState::Draft
            | ProposalState::Succeeded => Err(GovernanceError::InvalidStateNotFinal.into()),
        }
    }
    pub fn assert_can_cast_vote(
        &self,
        config: &GovernanceConfig,
        vote: &Vote,
        current_unix_timestamp: UnixTimestamp,
    ) -> Result<(), ProgramError> {
        self.assert_is_voting_state()
            .map_err(|_| GovernanceError::InvalidStateCannotVote)?;
        if self.has_voting_max_time_ended(config, current_unix_timestamp) {
            return Err(GovernanceError::ProposalVotingTimeExpired.into());
        }
        match vote {
            Vote::Approve(_) | Vote::Abstain => {
                if self.has_voting_base_time_ended(config, current_unix_timestamp) {
                    Err(GovernanceError::VoteNotAllowedInCoolOffTime.into())
                } else {
                    Ok(())
                }
            }
            Vote::Deny | Vote::Veto => Ok(()),
        }
    }
    pub fn assert_can_refund_proposal_deposit(&self) -> Result<(), ProgramError> {
        match self.state {
            ProposalState::Succeeded
            | ProposalState::Executing
            | ProposalState::Completed
            | ProposalState::Cancelled
            | ProposalState::Defeated
            | ProposalState::ExecutingWithErrors
            | ProposalState::Vetoed => Ok(()),
            ProposalState::Draft | ProposalState::SigningOff | ProposalState::Voting => {
                Err(GovernanceError::CannotRefundProposalDeposit.into())
            }
        }
    }
    pub fn voting_base_time_end(&self, config: &GovernanceConfig) -> UnixTimestamp {
        self.voting_at
            .unwrap()
            .checked_add(config.voting_base_time as i64)
            .unwrap()
    }
    pub fn has_voting_base_time_ended(
        &self,
        config: &GovernanceConfig,
        current_unix_timestamp: UnixTimestamp,
    ) -> bool {
        self.voting_base_time_end(config) < current_unix_timestamp
    }
    pub fn voting_max_time_end(&self, config: &GovernanceConfig) -> UnixTimestamp {
        self.voting_base_time_end(config)
            .checked_add(config.voting_cool_off_time as i64)
            .unwrap()
    }
    pub fn has_voting_max_time_ended(
        &self,
        config: &GovernanceConfig,
        current_unix_timestamp: UnixTimestamp,
    ) -> bool {
        self.voting_max_time_end(config) < current_unix_timestamp
    }
    pub fn assert_can_finalize_vote(
        &self,
        config: &GovernanceConfig,
        current_unix_timestamp: UnixTimestamp,
    ) -> Result<(), ProgramError> {
        self.assert_is_voting_state()
            .map_err(|_| GovernanceError::InvalidStateCannotFinalize)?;
        if !self.has_voting_max_time_ended(config, current_unix_timestamp) {
            return Err(GovernanceError::CannotFinalizeVotingInProgress.into());
        }
        Ok(())
    }
    pub fn finalize_vote(
        &mut self,
        max_voter_weight: u64,
        config: &GovernanceConfig,
        current_unix_timestamp: UnixTimestamp,
        vote_threshold: &VoteThreshold,
    ) -> Result<(), ProgramError> {
        self.assert_can_finalize_vote(config, current_unix_timestamp)?;
        self.state = self.resolve_final_vote_state(max_voter_weight, vote_threshold)?;
        self.voting_completed_at = Some(self.voting_max_time_end(config));
        self.max_vote_weight = Some(max_voter_weight);
        self.vote_threshold = Some(vote_threshold.clone());
        Ok(())
    }
    fn resolve_final_vote_state(
        &mut self,
        max_vote_weight: u64,
        vote_threshold: &VoteThreshold,
    ) -> Result<ProposalState, ProgramError> {
        let min_vote_threshold_weight =
            get_min_vote_threshold_weight(vote_threshold, max_vote_weight).unwrap();
        let deny_vote_weight = self.deny_vote_weight.unwrap_or(0);
        let mut best_succeeded_option_weight = 0;
        let mut best_succeeded_option_count = 0u16;
        for option in self.options.iter_mut() {
            if option.vote_weight >= min_vote_threshold_weight
                && option.vote_weight > deny_vote_weight
            {
                option.vote_result = OptionVoteResult::Succeeded;
                match option.vote_weight.cmp(&best_succeeded_option_weight) {
                    Ordering::Greater => {
                        best_succeeded_option_weight = option.vote_weight;
                        best_succeeded_option_count = 1;
                    }
                    Ordering::Equal => {
                        best_succeeded_option_count =
                            best_succeeded_option_count.checked_add(1).unwrap()
                    }
                    Ordering::Less => {}
                }
            } else {
                option.vote_result = OptionVoteResult::Defeated;
            }
        }
        let mut final_state = if best_succeeded_option_count == 0 {
            ProposalState::Defeated
        } else {
            match &self.vote_type {
                VoteType::SingleChoice => {
                    let proposal_state = if best_succeeded_option_count > 1 {
                        best_succeeded_option_weight = u64::MAX;
                        ProposalState::Defeated
                    } else {
                        ProposalState::Succeeded
                    };
                    for option in self.options.iter_mut() {
                        option.vote_result = if option.vote_weight == best_succeeded_option_weight {
                            OptionVoteResult::Succeeded
                        } else {
                            OptionVoteResult::Defeated
                        };
                    }
                    proposal_state
                }
                VoteType::MultiChoice {
                    choice_type: _,
                    max_voter_options: _,
                    max_winning_options: _,
                    min_voter_options: _,
                } => {
                    ProposalState::Succeeded
                }
            }
        };
        if self.deny_vote_weight.is_none() {
            final_state = ProposalState::Completed;
        }
        Ok(final_state)
    }
    fn get_max_voter_weight_from_mint_supply(
        &mut self,
        realm_data: &RealmV2,
        governing_token_mint: &Pubkey,
        governing_token_mint_supply: u64,
        vote_kind: &VoteKind,
    ) -> Result<u64, ProgramError> {
        if Some(*governing_token_mint) == realm_data.config.council_mint {
            return Ok(governing_token_mint_supply);
        }
        let max_voter_weight = match realm_data.config.community_mint_max_voter_weight_source {
            MintMaxVoterWeightSource::SupplyFraction(fraction) => {
                if fraction == MintMaxVoterWeightSource::SUPPLY_FRACTION_BASE {
                    return Ok(governing_token_mint_supply);
                }
                (governing_token_mint_supply as u128)
                    .checked_mul(fraction as u128)
                    .unwrap()
                    .checked_div(MintMaxVoterWeightSource::SUPPLY_FRACTION_BASE as u128)
                    .unwrap() as u64
            }
            MintMaxVoterWeightSource::Absolute(value) => value,
        };
        Ok(self.coerce_max_voter_weight(max_voter_weight, vote_kind))
    }
    fn coerce_max_voter_weight(&self, max_voter_weight: u64, vote_kind: &VoteKind) -> u64 {
        let total_vote_weight = match vote_kind {
            VoteKind::Electorate => {
                let deny_vote_weight = self.deny_vote_weight.unwrap_or(0);
                let max_option_vote_weight =
                    self.options.iter().map(|o| o.vote_weight).max().unwrap();
                max_option_vote_weight
                    .checked_add(deny_vote_weight)
                    .unwrap()
            }
            VoteKind::Veto => self.veto_vote_weight,
        };
        max_voter_weight.max(total_vote_weight)
    }
    #[allow(clippy::too_many_arguments)]
    pub fn resolve_max_voter_weight(
        &mut self,
        account_info_iter: &mut Iter<AccountInfo>,
        realm: &Pubkey,
        realm_data: &RealmV2,
        realm_config_data: &RealmConfigAccount,
        vote_governing_token_mint_info: &AccountInfo,
        vote_kind: &VoteKind,
    ) -> Result<u64, ProgramError> {
        if let Some(max_voter_weight_addin) = realm_config_data
            .get_token_config(realm_data, vote_governing_token_mint_info.key)?
            .max_voter_weight_addin
        {
            let max_voter_weight_record_info = next_account_info(account_info_iter)?;
            let max_voter_weight_record_data =
                get_max_voter_weight_record_data_for_realm_and_governing_token_mint(
                    &max_voter_weight_addin,
                    max_voter_weight_record_info,
                    realm,
                    vote_governing_token_mint_info.key,
                )?;
            assert_is_valid_max_voter_weight(&max_voter_weight_record_data)?;
            return Ok(self.coerce_max_voter_weight(
                max_voter_weight_record_data.max_voter_weight,
                vote_kind,
            ));
        }
        let vote_governing_token_mint_supply =
            get_spl_token_mint_supply(vote_governing_token_mint_info)?;
        let max_voter_weight = self.get_max_voter_weight_from_mint_supply(
            realm_data,
            vote_governing_token_mint_info.key,
            vote_governing_token_mint_supply,
            vote_kind,
        )?;
        Ok(max_voter_weight)
    }
    pub fn try_tip_vote(
        &mut self,
        max_voter_weight: u64,
        vote_tipping: &VoteTipping,
        current_unix_timestamp: UnixTimestamp,
        vote_threshold: &VoteThreshold,
        vote_kind: &VoteKind,
    ) -> Result<bool, ProgramError> {
        if let Some(tipped_state) = self.try_get_tipped_vote_state(
            max_voter_weight,
            vote_tipping,
            vote_threshold,
            vote_kind,
        ) {
            self.state = tipped_state;
            self.voting_completed_at = Some(current_unix_timestamp);
            self.max_vote_weight = Some(max_voter_weight);
            self.vote_threshold = Some(vote_threshold.clone());
            Ok(true)
        } else {
            Ok(false)
        }
    }
    pub fn try_get_tipped_vote_state(
        &mut self,
        max_voter_weight: u64,
        vote_tipping: &VoteTipping,
        vote_threshold: &VoteThreshold,
        vote_kind: &VoteKind,
    ) -> Option<ProposalState> {
        let min_vote_threshold_weight =
            get_min_vote_threshold_weight(vote_threshold, max_voter_weight).unwrap();
        match vote_kind {
            VoteKind::Electorate => self.try_get_tipped_electorate_vote_state(
                max_voter_weight,
                vote_tipping,
                min_vote_threshold_weight,
            ),
            VoteKind::Veto => self.try_get_tipped_veto_vote_state(min_vote_threshold_weight),
        }
    }
    fn try_get_tipped_electorate_vote_state(
        &mut self,
        max_voter_weight: u64,
        vote_tipping: &VoteTipping,
        min_vote_threshold_weight: u64,
    ) -> Option<ProposalState> {
        if self.vote_type != VoteType::SingleChoice
            || self.deny_vote_weight.is_none()
            || self.options.len() != 1
        {
            return None;
        };
        let yes_option = &mut self.options[0];
        let yes_vote_weight = yes_option.vote_weight;
        let deny_vote_weight = self.deny_vote_weight.unwrap();
        match vote_tipping {
            VoteTipping::Disabled => {}
            VoteTipping::Strict => {
                if yes_vote_weight >= min_vote_threshold_weight
                    && yes_vote_weight > (max_voter_weight.saturating_sub(yes_vote_weight))
                {
                    yes_option.vote_result = OptionVoteResult::Succeeded;
                    return Some(ProposalState::Succeeded);
                }
            }
            VoteTipping::Early => {
                if yes_vote_weight >= min_vote_threshold_weight
                    && yes_vote_weight > deny_vote_weight
                {
                    yes_option.vote_result = OptionVoteResult::Succeeded;
                    return Some(ProposalState::Succeeded);
                }
            }
        }
        if *vote_tipping != VoteTipping::Disabled
            && (deny_vote_weight > (max_voter_weight.saturating_sub(min_vote_threshold_weight))
                || deny_vote_weight >= (max_voter_weight.saturating_sub(deny_vote_weight)))
        {
            yes_option.vote_result = OptionVoteResult::Defeated;
            return Some(ProposalState::Defeated);
        }
        None
    }
    fn try_get_tipped_veto_vote_state(
        &mut self,
        min_vote_threshold_weight: u64,
    ) -> Option<ProposalState> {
        if self.veto_vote_weight >= min_vote_threshold_weight {
            Some(ProposalState::Vetoed)
        } else {
            None
        }
    }
    pub fn assert_can_cancel(
        &self,
        config: &GovernanceConfig,
        current_unix_timestamp: UnixTimestamp,
    ) -> Result<(), ProgramError> {
        match self.state {
            ProposalState::Draft | ProposalState::SigningOff => Ok(()),
            ProposalState::Voting => {
                if self.has_voting_max_time_ended(config, current_unix_timestamp) {
                    return Err(GovernanceError::ProposalVotingTimeExpired.into());
                }
                Ok(())
            }
            ProposalState::Executing
            | ProposalState::ExecutingWithErrors
            | ProposalState::Completed
            | ProposalState::Cancelled
            | ProposalState::Succeeded
            | ProposalState::Defeated
            | ProposalState::Vetoed => {
                Err(GovernanceError::InvalidStateCannotCancelProposal.into())
            }
        }
    }
    pub fn assert_can_edit_instructions(&self) -> Result<(), ProgramError> {
        if self.assert_is_draft_state().is_err() {
            return Err(GovernanceError::InvalidStateCannotEditTransactions.into());
        }
        if self.deny_vote_weight.is_none() {
            return Err(GovernanceError::ProposalIsNotExecutable.into());
        }
        Ok(())
    }
    pub fn assert_can_execute_transaction(
        &self,
        proposal_transaction_data: &ProposalTransactionV2,
        governance_config: &GovernanceConfig,
        current_unix_timestamp: UnixTimestamp,
    ) -> Result<(), ProgramError> {
        match self.state {
            ProposalState::Succeeded
            | ProposalState::Executing
            | ProposalState::ExecutingWithErrors => {}
            ProposalState::Draft
            | ProposalState::SigningOff
            | ProposalState::Completed
            | ProposalState::Voting
            | ProposalState::Cancelled
            | ProposalState::Defeated
            | ProposalState::Vetoed => {
                return Err(GovernanceError::InvalidStateCannotExecuteTransaction.into())
            }
        }
        if self.options[proposal_transaction_data.option_index as usize].vote_result
            != OptionVoteResult::Succeeded
        {
            return Err(GovernanceError::CannotExecuteDefeatedOption.into());
        }
        if self
            .voting_completed_at
            .unwrap()
            .checked_add(governance_config.transactions_hold_up_time as i64)
            .unwrap()
            >= current_unix_timestamp
        {
            return Err(GovernanceError::CannotExecuteTransactionWithinHoldUpTime.into());
        }
        if proposal_transaction_data.executed_at.is_some() {
            return Err(GovernanceError::TransactionAlreadyExecuted.into());
        }
        Ok(())
    }
    pub fn assert_can_complete(&self) -> Result<(), ProgramError> {
        if self.state != ProposalState::Succeeded {
            return Err(GovernanceError::InvalidStateToCompleteProposal.into());
        }
        if self.options.iter().any(|o| o.transactions_count != 0) {
            return Err(GovernanceError::InvalidStateToCompleteProposal.into());
        }
        Ok(())
    }
    pub fn assert_valid_vote(&self, vote: &Vote) -> Result<(), ProgramError> {
        match vote {
            Vote::Approve(choices) => {
                if self.options.len() != choices.len() {
                    return Err(GovernanceError::InvalidNumberOfVoteChoices.into());
                }
                let mut choice_count = 0u16;
                let mut total_choice_weight_percentage = 0u8;
                for choice in choices {
                    if choice.rank > 0 {
                        return Err(GovernanceError::RankedVoteIsNotSupported.into());
                    }
                    if choice.weight_percentage > 0 {
                        choice_count = choice_count.checked_add(1).unwrap();
                        match self.vote_type {
                            VoteType::MultiChoice {
                                choice_type: MultiChoiceType::Weighted,
                                min_voter_options: _,
                                max_voter_options: _,
                                max_winning_options: _,
                            } => {
                                total_choice_weight_percentage = total_choice_weight_percentage
                                    .checked_add(choice.weight_percentage)
                                    .ok_or(GovernanceError::TotalVoteWeightMustBe100Percent)?;
                            }
                            _ => {
                                if choice.weight_percentage != 100 {
                                    return Err(
                                        GovernanceError::ChoiceWeightMustBe100Percent.into()
                                    );
                                }
                            }
                        }
                    }
                }
                match self.vote_type {
                    VoteType::SingleChoice => {
                        if choice_count != 1 {
                            return Err(GovernanceError::SingleChoiceOnlyIsAllowed.into());
                        }
                    }
                    VoteType::MultiChoice {
                        choice_type: MultiChoiceType::FullWeight,
                        min_voter_options: _,
                        max_voter_options: _,
                        max_winning_options: _,
                    } => {
                        if choice_count == 0 {
                            return Err(GovernanceError::AtLeastSingleChoiceIsRequired.into());
                        }
                    }
                    VoteType::MultiChoice {
                        choice_type: MultiChoiceType::Weighted,
                        min_voter_options: _,
                        max_voter_options: _,
                        max_winning_options: _,
                    } => {
                        if choice_count == 0 {
                            return Err(GovernanceError::AtLeastSingleChoiceIsRequired.into());
                        }
                        if total_choice_weight_percentage != 100 {
                            return Err(GovernanceError::TotalVoteWeightMustBe100Percent.into());
                        }
                    }
                }
            }
            Vote::Deny => {
                if self.deny_vote_weight.is_none() {
                    return Err(GovernanceError::DenyVoteIsNotAllowed.into());
                }
            }
            Vote::Abstain => {
                return Err(GovernanceError::NotSupportedVoteType.into());
            }
            Vote::Veto => {}
        }
        Ok(())
    }
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if self.account_type == GovernanceAccountType::ProposalV2 {
            borsh::to_writer(writer, &self)?
        } else if self.account_type == GovernanceAccountType::ProposalV1 {
            if self.abstain_vote_weight.is_some() {
                panic!("ProposalV1 doesn't support Abstain vote")
            }
            if self.veto_vote_weight > 0 {
                panic!("ProposalV1 doesn't support Veto vote")
            }
            if self.start_voting_at.is_some() {
                panic!("ProposalV1 doesn't support start time")
            }
            if self.max_voting_time.is_some() {
                panic!("ProposalV1 doesn't support max voting time")
            }
            if self.options.len() != 1 {
                panic!("ProposalV1 doesn't support multiple options")
            }
            let proposal_data_v1 = ProposalV1 {
                account_type: self.account_type,
                governance: self.governance,
                governing_token_mint: self.governing_token_mint,
                state: self.state,
                token_owner_record: self.token_owner_record,
                signatories_count: self.signatories_count,
                signatories_signed_off_count: self.signatories_signed_off_count,
                yes_votes_count: self.options[0].vote_weight,
                no_votes_count: self.deny_vote_weight.unwrap(),
                instructions_executed_count: self.options[0].transactions_executed_count,
                instructions_count: self.options[0].transactions_count,
                instructions_next_index: self.options[0].transactions_next_index,
                draft_at: self.draft_at,
                signing_off_at: self.signing_off_at,
                voting_at: self.voting_at,
                voting_at_slot: self.voting_at_slot,
                voting_completed_at: self.voting_completed_at,
                executing_at: self.executing_at,
                closed_at: self.closed_at,
                execution_flags: self.execution_flags,
                max_vote_weight: self.max_vote_weight,
                vote_threshold: self.vote_threshold,
                name: self.name,
                description_link: self.description_link,
            };
            borsh::to_writer(writer, &proposal_data_v1)?
        }
        Ok(())
    }
}
fn get_min_vote_threshold_weight(
    vote_threshold: &VoteThreshold,
    max_voter_weight: u64,
) -> Result<u64, ProgramError> {
    let yes_vote_threshold_percentage = match vote_threshold {
        VoteThreshold::YesVotePercentage(yes_vote_threshold_percentage) => {
            *yes_vote_threshold_percentage
        }
        _ => {
            return Err(GovernanceError::VoteThresholdTypeNotSupported.into());
        }
    };
    let numerator = (yes_vote_threshold_percentage as u128)
        .checked_mul(max_voter_weight as u128)
        .unwrap();
    let mut yes_vote_threshold = numerator.checked_div(100).unwrap();
    if yes_vote_threshold.checked_mul(100).unwrap() < numerator {
        yes_vote_threshold = yes_vote_threshold.checked_add(1).unwrap();
    }
    Ok(yes_vote_threshold as u64)
}
pub fn get_proposal_data(
    program_id: &Pubkey,
    proposal_info: &AccountInfo,
) -> Result<ProposalV2, ProgramError> {
    let account_type: GovernanceAccountType = get_account_type(program_id, proposal_info)?;
    if account_type == GovernanceAccountType::ProposalV1 {
        let proposal_data_v1 = get_account_data::<ProposalV1>(program_id, proposal_info)?;
        let vote_result = match proposal_data_v1.state {
            ProposalState::Draft
            | ProposalState::SigningOff
            | ProposalState::Voting
            | ProposalState::Cancelled => OptionVoteResult::None,
            ProposalState::Succeeded
            | ProposalState::Executing
            | ProposalState::ExecutingWithErrors
            | ProposalState::Completed => OptionVoteResult::Succeeded,
            ProposalState::Vetoed | ProposalState::Defeated => OptionVoteResult::None,
        };
        return Ok(ProposalV2 {
            account_type,
            governance: proposal_data_v1.governance,
            governing_token_mint: proposal_data_v1.governing_token_mint,
            state: proposal_data_v1.state,
            token_owner_record: proposal_data_v1.token_owner_record,
            signatories_count: proposal_data_v1.signatories_count,
            signatories_signed_off_count: proposal_data_v1.signatories_signed_off_count,
            vote_type: VoteType::SingleChoice,
            options: vec![ProposalOption {
                label: "Yes".to_string(),
                vote_weight: proposal_data_v1.yes_votes_count,
                vote_result,
                transactions_executed_count: proposal_data_v1.instructions_executed_count,
                transactions_count: proposal_data_v1.instructions_count,
                transactions_next_index: proposal_data_v1.instructions_next_index,
            }],
            deny_vote_weight: Some(proposal_data_v1.no_votes_count),
            veto_vote_weight: 0,
            abstain_vote_weight: None,
            start_voting_at: None,
            draft_at: proposal_data_v1.draft_at,
            signing_off_at: proposal_data_v1.signing_off_at,
            voting_at: proposal_data_v1.voting_at,
            voting_at_slot: proposal_data_v1.voting_at_slot,
            voting_completed_at: proposal_data_v1.voting_completed_at,
            executing_at: proposal_data_v1.executing_at,
            closed_at: proposal_data_v1.closed_at,
            execution_flags: proposal_data_v1.execution_flags,
            max_vote_weight: proposal_data_v1.max_vote_weight,
            max_voting_time: None,
            vote_threshold: proposal_data_v1.vote_threshold,
            name: proposal_data_v1.name,
            description_link: proposal_data_v1.description_link,
            reserved: [0; 64],
            reserved1: 0,
        });
    }
    get_account_data::<ProposalV2>(program_id, proposal_info)
}
pub fn get_proposal_data_for_governance_and_governing_mint(
    program_id: &Pubkey,
    proposal_info: &AccountInfo,
    governance: &Pubkey,
    governing_token_mint: &Pubkey,
) -> Result<ProposalV2, ProgramError> {
    let proposal_data = get_proposal_data_for_governance(program_id, proposal_info, governance)?;
    if proposal_data.governing_token_mint != *governing_token_mint {
        return Err(GovernanceError::InvalidGoverningMintForProposal.into());
    }
    Ok(proposal_data)
}
pub fn get_proposal_data_for_governance(
    program_id: &Pubkey,
    proposal_info: &AccountInfo,
    governance: &Pubkey,
) -> Result<ProposalV2, ProgramError> {
    let proposal_data = get_proposal_data(program_id, proposal_info)?;
    if proposal_data.governance != *governance {
        return Err(GovernanceError::InvalidGovernanceForProposal.into());
    }
    Ok(proposal_data)
}
pub fn get_proposal_address_seeds<'a>(
    governance: &'a Pubkey,
    governing_token_mint: &'a Pubkey,
    proposal_seed: &'a Pubkey,
) -> [&'a [u8]; 4] {
    [
        PROGRAM_AUTHORITY_SEED,
        governance.as_ref(),
        governing_token_mint.as_ref(),
        proposal_seed.as_ref(),
    ]
}
pub fn get_proposal_address<'a>(
    program_id: &Pubkey,
    governance: &'a Pubkey,
    governing_token_mint: &'a Pubkey,
    proposal_seed: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_proposal_address_seeds(governance, governing_token_mint, proposal_seed),
        program_id,
    )
    .0
}
pub fn assert_valid_proposal_options(
    options: &[String],
    vote_type: &VoteType,
) -> Result<(), ProgramError> {
    if options.is_empty() || options.len() > 10 {
        return Err(GovernanceError::InvalidProposalOptions.into());
    }
    if let VoteType::MultiChoice {
        choice_type: _,
        min_voter_options,
        max_voter_options,
        max_winning_options,
    } = vote_type
    {
        if options.len() == 1
            || *max_voter_options as usize != options.len()
            || *max_winning_options as usize != options.len()
            || *min_voter_options != 1
        {
            return Err(GovernanceError::InvalidMultiChoiceProposalParameters.into());
        }
    }
    if options.iter().any(|o| o.is_empty()) {
        return Err(GovernanceError::InvalidProposalOptions.into());
    }
    Ok(())
}