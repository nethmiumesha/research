use {
    crate::{
        error::GovernanceError,
        state::{
            enums::{GovernanceAccountType, VoteThreshold, VoteTipping},
            legacy::{is_governance_v1_account_type, GovernanceV1},
            realm::{assert_is_valid_realm, RealmV2},
            vote_record::VoteKind,
        },
        tools::structs::Reserved119,
    },
    borsh::{io::Write, BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::AccountInfo, program_error::ProgramError, program_pack::IsInitialized,
        pubkey::Pubkey, rent::Rent,
    },
    spl_governance_tools::{
        account::{
            assert_is_valid_account_of_types, extend_account_size, get_account_data,
            get_account_type, AccountMaxSize,
        },
        error::GovernanceToolsError,
    },
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct GovernanceConfig {
    pub community_vote_threshold: VoteThreshold,
    pub min_community_weight_to_create_proposal: u64,
    pub transactions_hold_up_time: u32,
    pub voting_base_time: u32,
    pub community_vote_tipping: VoteTipping,
    pub council_vote_threshold: VoteThreshold,
    pub council_veto_vote_threshold: VoteThreshold,
    pub min_council_weight_to_create_proposal: u64,
    pub council_vote_tipping: VoteTipping,
    pub community_veto_vote_threshold: VoteThreshold,
    pub voting_cool_off_time: u32,
    pub deposit_exempt_proposal_count: u8,
}
pub const DEFAULT_DEPOSIT_EXEMPT_PROPOSAL_COUNT: u8 = 10;
pub const SECURITY_DEPOSIT_BASE_LAMPORTS: u64 = 100_000_000;
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct GovernanceV2 {
    pub account_type: GovernanceAccountType,
    pub realm: Pubkey,
    pub governance_seed: Pubkey,
    pub reserved1: u32,
    pub config: GovernanceConfig,
    pub reserved_v2: Reserved119,
    pub required_signatories_count: u8,
    pub active_proposal_count: u64,
}
impl AccountMaxSize for GovernanceV2 {
    fn get_max_size(&self) -> Option<usize> {
        Some(236)
    }
}
pub fn is_governance_v2_account_type(account_type: &GovernanceAccountType) -> bool {
    match account_type {
        GovernanceAccountType::GovernanceV2
        | GovernanceAccountType::ProgramGovernanceV2
        | GovernanceAccountType::MintGovernanceV2
        | GovernanceAccountType::TokenGovernanceV2 => true,
        GovernanceAccountType::Uninitialized
        | GovernanceAccountType::RealmV1
        | GovernanceAccountType::RealmV2
        | GovernanceAccountType::RealmConfig
        | GovernanceAccountType::TokenOwnerRecordV1
        | GovernanceAccountType::TokenOwnerRecordV2
        | GovernanceAccountType::GovernanceV1
        | GovernanceAccountType::ProgramGovernanceV1
        | GovernanceAccountType::MintGovernanceV1
        | GovernanceAccountType::TokenGovernanceV1
        | GovernanceAccountType::ProposalV1
        | GovernanceAccountType::ProposalV2
        | GovernanceAccountType::SignatoryRecordV1
        | GovernanceAccountType::SignatoryRecordV2
        | GovernanceAccountType::ProposalInstructionV1
        | GovernanceAccountType::ProposalTransactionV2
        | GovernanceAccountType::VoteRecordV1
        | GovernanceAccountType::VoteRecordV2
        | GovernanceAccountType::ProgramMetadata
        | GovernanceAccountType::ProposalDeposit
        | GovernanceAccountType::RequiredSignatory => false,
    }
}
pub fn try_get_governance_v2_type_for_v1(
    account_type: &GovernanceAccountType,
) -> Option<GovernanceAccountType> {
    match account_type {
        GovernanceAccountType::GovernanceV1 => Some(GovernanceAccountType::GovernanceV2),
        GovernanceAccountType::ProgramGovernanceV1 => {
            Some(GovernanceAccountType::ProgramGovernanceV2)
        }
        GovernanceAccountType::MintGovernanceV1 => Some(GovernanceAccountType::MintGovernanceV2),
        GovernanceAccountType::TokenGovernanceV1 => Some(GovernanceAccountType::TokenGovernanceV2),
        GovernanceAccountType::Uninitialized
        | GovernanceAccountType::RealmV1
        | GovernanceAccountType::RealmV2
        | GovernanceAccountType::RealmConfig
        | GovernanceAccountType::TokenOwnerRecordV1
        | GovernanceAccountType::TokenOwnerRecordV2
        | GovernanceAccountType::GovernanceV2
        | GovernanceAccountType::ProgramGovernanceV2
        | GovernanceAccountType::MintGovernanceV2
        | GovernanceAccountType::TokenGovernanceV2
        | GovernanceAccountType::ProposalV1
        | GovernanceAccountType::ProposalV2
        | GovernanceAccountType::SignatoryRecordV1
        | GovernanceAccountType::SignatoryRecordV2
        | GovernanceAccountType::ProposalInstructionV1
        | GovernanceAccountType::ProposalTransactionV2
        | GovernanceAccountType::VoteRecordV1
        | GovernanceAccountType::VoteRecordV2
        | GovernanceAccountType::ProgramMetadata
        | GovernanceAccountType::ProposalDeposit
        | GovernanceAccountType::RequiredSignatory => None,
    }
}
pub fn is_governance_account_type(account_type: &GovernanceAccountType) -> bool {
    is_governance_v1_account_type(account_type) || is_governance_v2_account_type(account_type)
}
impl IsInitialized for GovernanceV2 {
    fn is_initialized(&self) -> bool {
        is_governance_v2_account_type(&self.account_type)
    }
}
impl GovernanceV2 {
    pub fn get_governance_address_seeds(&self) -> Result<[&[u8]; 3], ProgramError> {
        let seeds = match self.account_type {
            GovernanceAccountType::GovernanceV1 | GovernanceAccountType::GovernanceV2 => {
                get_governance_address_seeds(&self.realm, &self.governance_seed)
            }
            GovernanceAccountType::ProgramGovernanceV1
            | GovernanceAccountType::ProgramGovernanceV2 => {
                get_program_governance_address_seeds(&self.realm, &self.governance_seed)
            }
            GovernanceAccountType::MintGovernanceV1 | GovernanceAccountType::MintGovernanceV2 => {
                get_mint_governance_address_seeds(&self.realm, &self.governance_seed)
            }
            GovernanceAccountType::TokenGovernanceV1 | GovernanceAccountType::TokenGovernanceV2 => {
                get_token_governance_address_seeds(&self.realm, &self.governance_seed)
            }
            GovernanceAccountType::Uninitialized
            | GovernanceAccountType::RealmV1
            | GovernanceAccountType::TokenOwnerRecordV1
            | GovernanceAccountType::ProposalV1
            | GovernanceAccountType::SignatoryRecordV1
            | GovernanceAccountType::VoteRecordV1
            | GovernanceAccountType::ProposalInstructionV1
            | GovernanceAccountType::RealmConfig
            | GovernanceAccountType::VoteRecordV2
            | GovernanceAccountType::ProposalTransactionV2
            | GovernanceAccountType::ProposalV2
            | GovernanceAccountType::ProgramMetadata
            | GovernanceAccountType::ProposalDeposit
            | GovernanceAccountType::RealmV2
            | GovernanceAccountType::TokenOwnerRecordV2
            | GovernanceAccountType::SignatoryRecordV2
            | GovernanceAccountType::RequiredSignatory => {
                return Err(GovernanceToolsError::InvalidAccountType.into())
            }
        };
        Ok(seeds)
    }
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if is_governance_v2_account_type(&self.account_type) {
            borsh::to_writer(writer, &self)?
        } else if is_governance_v1_account_type(&self.account_type) {
            if self.reserved_v2 != Reserved119::default() {
                panic!("Extended data not supported by GovernanceV1")
            }
            let governance_data_v1 = GovernanceV1 {
                account_type: self.account_type,
                realm: self.realm,
                governance_seed: self.governance_seed,
                proposals_count: 0,
                config: self.config,
            };
            borsh::to_writer(writer, &governance_data_v1)?
        }
        Ok(())
    }
    pub fn serialize_as_governance_v2<'a>(
        mut self,
        governance_info: &AccountInfo<'a>,
        payer_info: &AccountInfo<'a>,
        system_info: &AccountInfo<'a>,
        rent: &Rent,
    ) -> Result<(), ProgramError> {
        if let Some(governance_v2_type) = try_get_governance_v2_type_for_v1(&self.account_type) {
            self.account_type = governance_v2_type;
            extend_account_size(
                governance_info,
                payer_info,
                self.get_max_size().unwrap(),
                rent,
                system_info,
            )?;
        }
        self.serialize(&mut governance_info.data.borrow_mut()[..])
    }
    pub fn assert_governing_token_mint_can_vote(
        &self,
        realm_data: &RealmV2,
        vote_governing_token_mint: &Pubkey,
        vote_kind: &VoteKind,
    ) -> Result<(), ProgramError> {
        let _ = self.resolve_vote_threshold(realm_data, vote_governing_token_mint, vote_kind)?;
        Ok(())
    }
    pub fn resolve_vote_threshold(
        &self,
        realm_data: &RealmV2,
        vote_governing_token_mint: &Pubkey,
        vote_kind: &VoteKind,
    ) -> Result<VoteThreshold, ProgramError> {
        let vote_threshold = if realm_data.community_mint == *vote_governing_token_mint {
            match vote_kind {
                VoteKind::Electorate => &self.config.community_vote_threshold,
                VoteKind::Veto => &self.config.community_veto_vote_threshold,
            }
        } else if realm_data.config.council_mint == Some(*vote_governing_token_mint) {
            match vote_kind {
                VoteKind::Electorate => &self.config.council_vote_threshold,
                VoteKind::Veto => &self.config.council_veto_vote_threshold,
            }
        } else {
            return Err(GovernanceError::InvalidGoverningTokenMint.into());
        };
        if *vote_threshold == VoteThreshold::Disabled {
            return Err(GovernanceError::GoverningTokenMintNotAllowedToVote.into());
        }
        Ok(vote_threshold.clone())
    }
    pub fn get_vote_tipping(
        &self,
        realm_data: &RealmV2,
        governing_token_mint: &Pubkey,
    ) -> Result<&VoteTipping, ProgramError> {
        let vote_tipping = if *governing_token_mint == realm_data.community_mint {
            &self.config.community_vote_tipping
        } else if Some(*governing_token_mint) == realm_data.config.council_mint {
            &self.config.council_vote_tipping
        } else {
            return Err(GovernanceError::InvalidGoverningTokenMint.into());
        };
        Ok(vote_tipping)
    }
    pub fn get_proposal_deposit_amount(&self) -> u64 {
        self.active_proposal_count
            .saturating_sub(self.config.deposit_exempt_proposal_count as u64)
            .saturating_mul(SECURITY_DEPOSIT_BASE_LAMPORTS)
    }
}
pub fn get_governance_data(
    program_id: &Pubkey,
    governance_info: &AccountInfo,
) -> Result<GovernanceV2, ProgramError> {
    let account_type: GovernanceAccountType = get_account_type(program_id, governance_info)?;
    let mut governance_data = if is_governance_v1_account_type(&account_type) {
        let governance_data_v1 = get_account_data::<GovernanceV1>(program_id, governance_info)?;
        GovernanceV2 {
            account_type,
            realm: governance_data_v1.realm,
            governance_seed: governance_data_v1.governance_seed,
            reserved1: 0,
            config: governance_data_v1.config,
            reserved_v2: Reserved119::default(),
            required_signatories_count: 0,
            active_proposal_count: 0,
        }
    } else {
        get_account_data::<GovernanceV2>(program_id, governance_info)?
    };
    if governance_data.config.council_vote_threshold == VoteThreshold::YesVotePercentage(0) {
        governance_data.config.council_vote_threshold =
            governance_data.config.community_vote_threshold.clone();
        governance_data.config.council_veto_vote_threshold =
            governance_data.config.council_vote_threshold.clone();
        governance_data.config.council_vote_tipping =
            governance_data.config.community_vote_tipping.clone();
        governance_data.config.community_veto_vote_threshold = VoteThreshold::Disabled;
        governance_data.config.voting_cool_off_time = 0;
        governance_data.config.deposit_exempt_proposal_count =
            DEFAULT_DEPOSIT_EXEMPT_PROPOSAL_COUNT;
        governance_data.reserved1 = 0;
    }
    Ok(governance_data)
}
pub fn get_governance_data_for_realm(
    program_id: &Pubkey,
    governance_info: &AccountInfo,
    realm: &Pubkey,
) -> Result<GovernanceV2, ProgramError> {
    let governance_data = get_governance_data(program_id, governance_info)?;
    if governance_data.realm != *realm {
        return Err(GovernanceError::InvalidRealmForGovernance.into());
    }
    Ok(governance_data)
}
pub fn assert_governance_for_realm(
    program_id: &Pubkey,
    governance_info: &AccountInfo,
    realm: &Pubkey,
) -> Result<(), ProgramError> {
    get_governance_data_for_realm(program_id, governance_info, realm)?;
    Ok(())
}
pub fn get_program_governance_address_seeds<'a>(
    realm: &'a Pubkey,
    governed_program: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        b"program-governance",
        realm.as_ref(),
        governed_program.as_ref(),
    ]
}
pub fn get_program_governance_address<'a>(
    program_id: &Pubkey,
    realm: &'a Pubkey,
    governed_program: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_program_governance_address_seeds(realm, governed_program),
        program_id,
    )
    .0
}
pub fn get_mint_governance_address_seeds<'a>(
    realm: &'a Pubkey,
    governed_mint: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [b"mint-governance", realm.as_ref(), governed_mint.as_ref()]
}
pub fn get_mint_governance_address<'a>(
    program_id: &Pubkey,
    realm: &'a Pubkey,
    governed_mint: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_mint_governance_address_seeds(realm, governed_mint),
        program_id,
    )
    .0
}
pub fn get_token_governance_address_seeds<'a>(
    realm: &'a Pubkey,
    governed_token_account: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        b"token-governance",
        realm.as_ref(),
        governed_token_account.as_ref(),
    ]
}
pub fn get_token_governance_address<'a>(
    program_id: &Pubkey,
    realm: &'a Pubkey,
    governed_token_account: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_token_governance_address_seeds(realm, governed_token_account),
        program_id,
    )
    .0
}
pub fn get_governance_address_seeds<'a>(
    realm: &'a Pubkey,
    governance_seed: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        b"account-governance",
        realm.as_ref(),
        governance_seed.as_ref(),
    ]
}
pub fn get_governance_address<'a>(
    program_id: &Pubkey,
    realm: &'a Pubkey,
    governance_seed: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_governance_address_seeds(realm, governance_seed),
        program_id,
    )
    .0
}
pub fn assert_is_valid_governance(
    program_id: &Pubkey,
    governance_info: &AccountInfo,
) -> Result<(), ProgramError> {
    assert_is_valid_account_of_types(program_id, governance_info, is_governance_account_type)
}
pub fn assert_valid_create_governance_args(
    program_id: &Pubkey,
    governance_config: &GovernanceConfig,
    realm_info: &AccountInfo,
) -> Result<(), ProgramError> {
    assert_is_valid_realm(program_id, realm_info)?;
    assert_is_valid_governance_config(governance_config)?;
    Ok(())
}
pub fn assert_is_valid_governance_config(
    governance_config: &GovernanceConfig,
) -> Result<(), ProgramError> {
    assert_is_valid_vote_threshold(&governance_config.community_vote_threshold)?;
    assert_is_valid_vote_threshold(&governance_config.community_veto_vote_threshold)?;
    assert_is_valid_vote_threshold(&governance_config.council_vote_threshold)?;
    assert_is_valid_vote_threshold(&governance_config.council_veto_vote_threshold)?;
    if governance_config.community_vote_threshold == VoteThreshold::Disabled
        && governance_config.council_vote_threshold == VoteThreshold::Disabled
    {
        return Err(GovernanceError::AtLeastOneVoteThresholdRequired.into());
    }
    if governance_config.deposit_exempt_proposal_count == u8::MAX {
        return Err(GovernanceError::InvalidDepositExemptProposalCount.into());
    }
    Ok(())
}
pub fn assert_is_valid_vote_threshold(vote_threshold: &VoteThreshold) -> Result<(), ProgramError> {
    match *vote_threshold {
        VoteThreshold::YesVotePercentage(yes_vote_threshold_percentage) => {
            if !(1..=100).contains(&yes_vote_threshold_percentage) {
                return Err(GovernanceError::InvalidVoteThresholdPercentage.into());
            }
        }
        VoteThreshold::QuorumPercentage(_) => {
            return Err(GovernanceError::VoteThresholdTypeNotSupported.into());
        }
        VoteThreshold::Disabled => {}
    }
    Ok(())
}