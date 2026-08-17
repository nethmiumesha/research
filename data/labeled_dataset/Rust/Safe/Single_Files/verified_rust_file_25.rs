use {
    crate::{
        error::GovernanceError,
        state::{
            enums::GovernanceAccountType,
            legacy::{VoteRecordV1, VoteWeightV1},
            proposal::ProposalV2,
            realm::RealmV2,
            token_owner_record::TokenOwnerRecordV2,
        },
        PROGRAM_AUTHORITY_SEED,
    },
    borsh::{io::Write, BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::AccountInfo, program_error::ProgramError, program_pack::IsInitialized,
        pubkey::Pubkey,
    },
    spl_governance_tools::account::{get_account_data, get_account_type, AccountMaxSize},
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct VoteChoice {
    pub rank: u8,
    pub weight_percentage: u8,
}
impl VoteChoice {
    pub fn get_choice_weight(&self, voter_weight: u64) -> Result<u64, ProgramError> {
        Ok(match self.weight_percentage {
            100 => voter_weight,
            0..=99 => (voter_weight as u128)
                .checked_mul(self.weight_percentage as u128)
                .unwrap()
                .checked_div(100)
                .unwrap() as u64,
            _ => return Err(GovernanceError::InvalidVoteChoiceWeightPercentage.into()),
        })
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum Vote {
    Approve(Vec<VoteChoice>),
    Deny,
    Abstain,
    Veto,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum VoteKind {
    Electorate,
    Veto,
}
pub fn get_vote_kind(vote: &Vote) -> VoteKind {
    match vote {
        Vote::Approve(_) | Vote::Deny | Vote::Abstain => VoteKind::Electorate,
        Vote::Veto => VoteKind::Veto,
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct VoteRecordV2 {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub governing_token_owner: Pubkey,
    pub is_relinquished: bool,
    pub voter_weight: u64,
    pub vote: Vote,
    pub reserved_v2: [u8; 8],
}
impl AccountMaxSize for VoteRecordV2 {}
impl IsInitialized for VoteRecordV2 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::VoteRecordV2
    }
}
impl VoteRecordV2 {
    pub fn assert_can_relinquish_vote(&self) -> Result<(), ProgramError> {
        if self.is_relinquished {
            return Err(GovernanceError::VoteAlreadyRelinquished.into());
        }
        Ok(())
    }
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if self.account_type == GovernanceAccountType::VoteRecordV2 {
            borsh::to_writer(writer, &self)?
        } else if self.account_type == GovernanceAccountType::VoteRecordV1 {
            if self.reserved_v2 != [0; 8] {
                panic!("Extended data not supported by VoteRecordV1")
            }
            let vote_weight = match &self.vote {
                Vote::Approve(_options) => VoteWeightV1::Yes(self.voter_weight),
                Vote::Deny => VoteWeightV1::No(self.voter_weight),
                Vote::Abstain | Vote::Veto => {
                    panic!("Vote type: {:?} not supported by VoteRecordV1", &self.vote)
                }
            };
            let vote_record_data_v1 = VoteRecordV1 {
                account_type: self.account_type,
                proposal: self.proposal,
                governing_token_owner: self.governing_token_owner,
                is_relinquished: self.is_relinquished,
                vote_weight,
            };
            borsh::to_writer(writer, &vote_record_data_v1)?
        }
        Ok(())
    }
}
pub fn get_vote_record_data(
    program_id: &Pubkey,
    vote_record_info: &AccountInfo,
) -> Result<VoteRecordV2, ProgramError> {
    let account_type: GovernanceAccountType = get_account_type(program_id, vote_record_info)?;
    if account_type == GovernanceAccountType::VoteRecordV1 {
        let vote_record_data_v1 = get_account_data::<VoteRecordV1>(program_id, vote_record_info)?;
        let (vote, voter_weight) = match vote_record_data_v1.vote_weight {
            VoteWeightV1::Yes(weight) => (
                Vote::Approve(vec![VoteChoice {
                    rank: 0,
                    weight_percentage: 100,
                }]),
                weight,
            ),
            VoteWeightV1::No(weight) => (Vote::Deny, weight),
        };
        return Ok(VoteRecordV2 {
            account_type,
            proposal: vote_record_data_v1.proposal,
            governing_token_owner: vote_record_data_v1.governing_token_owner,
            is_relinquished: vote_record_data_v1.is_relinquished,
            voter_weight,
            vote,
            reserved_v2: [0; 8],
        });
    }
    get_account_data::<VoteRecordV2>(program_id, vote_record_info)
}
pub fn get_vote_record_data_for_proposal_and_token_owner_record(
    program_id: &Pubkey,
    vote_record_info: &AccountInfo,
    realm_data: &RealmV2,
    proposal: &Pubkey,
    proposal_data: &ProposalV2,
    token_owner_record_data: &TokenOwnerRecordV2,
) -> Result<VoteRecordV2, ProgramError> {
    let vote_record_data = get_vote_record_data(program_id, vote_record_info)?;
    if vote_record_data.proposal != *proposal {
        return Err(GovernanceError::InvalidProposalForVoterRecord.into());
    }
    if vote_record_data.governing_token_owner != token_owner_record_data.governing_token_owner {
        return Err(GovernanceError::InvalidGoverningTokenOwnerForVoteRecord.into());
    }
    let proposal_governing_token_mint = realm_data.get_proposal_governing_token_mint_for_vote(
        &token_owner_record_data.governing_token_mint,
        &get_vote_kind(&vote_record_data.vote),
    )?;
    if proposal_data.governing_token_mint != proposal_governing_token_mint {
        return Err(GovernanceError::InvalidGoverningMintForProposal.into());
    }
    Ok(vote_record_data)
}
pub fn get_vote_record_address_seeds<'a>(
    proposal: &'a Pubkey,
    token_owner_record: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        PROGRAM_AUTHORITY_SEED,
        proposal.as_ref(),
        token_owner_record.as_ref(),
    ]
}
pub fn get_vote_record_address<'a>(
    program_id: &Pubkey,
    proposal: &'a Pubkey,
    token_owner_record: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_vote_record_address_seeds(proposal, token_owner_record),
        program_id,
    )
    .0
}