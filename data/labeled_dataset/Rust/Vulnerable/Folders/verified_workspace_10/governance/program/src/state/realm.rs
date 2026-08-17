use {
    crate::{
        error::GovernanceError,
        state::{
            enums::{GovernanceAccountType, MintMaxVoterWeightSource},
            legacy::RealmV1,
            realm_config::{get_realm_config_data_for_realm, GoverningTokenType},
            token_owner_record::get_token_owner_record_data_for_realm,
            vote_record::VoteKind,
        },
        tools::structs::SetConfigItemActionType,
        PROGRAM_AUTHORITY_SEED,
    },
    borsh::{io::Write, BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::{next_account_info, AccountInfo},
        program_error::ProgramError,
        program_pack::IsInitialized,
        pubkey::Pubkey,
    },
    spl_governance_addin_api::voter_weight::VoterWeightAction,
    spl_governance_tools::account::{
        assert_is_valid_account_of_types, get_account_data, get_account_type, AccountMaxSize,
    },
    std::slice::Iter,
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum SetRealmConfigItemArgs {
    TokenOwnerRecordLockAuthority {
        #[allow(dead_code)]
        action: SetConfigItemActionType,
        #[allow(dead_code)]
        governing_token_mint: Pubkey,
        #[allow(dead_code)]
        authority: Pubkey,
    },
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct RealmConfigArgs {
    pub use_council_mint: bool,
    pub min_community_weight_to_create_governance: u64,
    pub community_mint_max_voter_weight_source: MintMaxVoterWeightSource,
    pub community_token_config_args: GoverningTokenConfigArgs,
    pub council_token_config_args: GoverningTokenConfigArgs,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema, Default)]
pub struct GoverningTokenConfigArgs {
    pub use_voter_weight_addin: bool,
    pub use_max_voter_weight_addin: bool,
    pub token_type: GoverningTokenType,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema, Default)]
pub struct GoverningTokenConfigAccountArgs {
    pub voter_weight_addin: Option<Pubkey>,
    pub max_voter_weight_addin: Option<Pubkey>,
    pub token_type: GoverningTokenType,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub enum SetRealmAuthorityAction {
    SetUnchecked,
    SetChecked,
    Remove,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct RealmConfig {
    pub legacy1: u8,
    pub legacy2: u8,
    pub reserved: [u8; 6],
    pub min_community_weight_to_create_governance: u64,
    pub community_mint_max_voter_weight_source: MintMaxVoterWeightSource,
    pub council_mint: Option<Pubkey>,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct RealmV2 {
    pub account_type: GovernanceAccountType,
    pub community_mint: Pubkey,
    pub config: RealmConfig,
    pub reserved: [u8; 6],
    pub legacy1: u16,
    pub authority: Option<Pubkey>,
    pub name: String,
    pub reserved_v2: [u8; 128],
}
impl AccountMaxSize for RealmV2 {
    fn get_max_size(&self) -> Option<usize> {
        Some(self.name.len() + 264)
    }
}
impl IsInitialized for RealmV2 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::RealmV2
    }
}
pub fn is_realm_account_type(account_type: &GovernanceAccountType) -> bool {
    match account_type {
        GovernanceAccountType::RealmV1 | GovernanceAccountType::RealmV2 => true,
        GovernanceAccountType::GovernanceV2
        | GovernanceAccountType::ProgramGovernanceV2
        | GovernanceAccountType::MintGovernanceV2
        | GovernanceAccountType::TokenGovernanceV2
        | GovernanceAccountType::Uninitialized
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
impl RealmV2 {
    pub fn assert_is_valid_governing_token_mint(
        &self,
        governing_token_mint: &Pubkey,
    ) -> Result<(), ProgramError> {
        if self.community_mint == *governing_token_mint {
            return Ok(());
        }
        if self.config.council_mint == Some(*governing_token_mint) {
            return Ok(());
        }
        Err(GovernanceError::InvalidGoverningTokenMint.into())
    }
    pub fn get_proposal_governing_token_mint_for_vote(
        &self,
        vote_governing_token_mint: &Pubkey,
        vote_kind: &VoteKind,
    ) -> Result<Pubkey, ProgramError> {
        match vote_kind {
            VoteKind::Electorate => Ok(*vote_governing_token_mint),
            VoteKind::Veto => {
                if self.community_mint == *vote_governing_token_mint {
                    return Ok(self.config.council_mint.unwrap());
                }
                if self.config.council_mint == Some(*vote_governing_token_mint) {
                    return Ok(self.community_mint);
                }
                Err(GovernanceError::InvalidGoverningTokenMint.into())
            }
        }
    }
    pub fn assert_is_valid_governing_token_mint_and_holding(
        &self,
        program_id: &Pubkey,
        realm: &Pubkey,
        governing_token_mint: &Pubkey,
        governing_token_holding: &Pubkey,
    ) -> Result<(), ProgramError> {
        self.assert_is_valid_governing_token_mint(governing_token_mint)?;
        let governing_token_holding_address =
            get_governing_token_holding_address(program_id, realm, governing_token_mint);
        if governing_token_holding_address != *governing_token_holding {
            return Err(GovernanceError::InvalidGoverningTokenHoldingAccount.into());
        }
        Ok(())
    }
    pub fn assert_create_authority_can_create_governance(
        &self,
        program_id: &Pubkey,
        realm: &Pubkey,
        token_owner_record_info: &AccountInfo,
        create_authority_info: &AccountInfo,
        account_info_iter: &mut Iter<AccountInfo>,
    ) -> Result<(), ProgramError> {
        if self.authority == Some(*create_authority_info.key) {
            return if !create_authority_info.is_signer {
                Err(GovernanceError::RealmAuthorityMustSign.into())
            } else {
                Ok(())
            };
        }
        let token_owner_record_data =
            get_token_owner_record_data_for_realm(program_id, token_owner_record_info, realm)?;
        token_owner_record_data.assert_token_owner_or_delegate_is_signer(create_authority_info)?;
        let realm_config_info = next_account_info(account_info_iter)?;
        let realm_config_data =
            get_realm_config_data_for_realm(program_id, realm_config_info, realm)?;
        let voter_weight = token_owner_record_data.resolve_voter_weight(
            account_info_iter,
            self,
            &realm_config_data,
            VoterWeightAction::CreateGovernance,
            realm,
        )?;
        token_owner_record_data.assert_can_create_governance(self, voter_weight)?;
        Ok(())
    }
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if self.account_type == GovernanceAccountType::RealmV2 {
            borsh::to_writer(writer, &self)?
        } else if self.account_type == GovernanceAccountType::RealmV1 {
            if self.reserved_v2 != [0; 128] {
                panic!("Extended data not supported by RealmV1")
            }
            let realm_data_v1 = RealmV1 {
                account_type: self.account_type,
                community_mint: self.community_mint,
                config: self.config,
                reserved: self.reserved,
                voting_proposal_count: 0,
                authority: self.authority,
                name: self.name,
            };
            borsh::to_writer(writer, &realm_data_v1)?
        }
        Ok(())
    }
}
pub fn assert_is_valid_realm(
    program_id: &Pubkey,
    realm_info: &AccountInfo,
) -> Result<(), ProgramError> {
    assert_is_valid_account_of_types(program_id, realm_info, is_realm_account_type)
}
pub fn get_realm_data(
    program_id: &Pubkey,
    realm_info: &AccountInfo,
) -> Result<RealmV2, ProgramError> {
    let account_type: GovernanceAccountType = get_account_type(program_id, realm_info)?;
    if account_type == GovernanceAccountType::RealmV1 {
        let realm_data_v1 = get_account_data::<RealmV1>(program_id, realm_info)?;
        return Ok(RealmV2 {
            account_type,
            community_mint: realm_data_v1.community_mint,
            config: realm_data_v1.config,
            reserved: realm_data_v1.reserved,
            legacy1: 0,
            authority: realm_data_v1.authority,
            name: realm_data_v1.name,
            reserved_v2: [0; 128],
        });
    }
    get_account_data::<RealmV2>(program_id, realm_info)
}
pub fn get_realm_data_for_authority(
    program_id: &Pubkey,
    realm_info: &AccountInfo,
    realm_authority: &Pubkey,
) -> Result<RealmV2, ProgramError> {
    let realm_data = get_realm_data(program_id, realm_info)?;
    if realm_data.authority.is_none() {
        return Err(GovernanceError::RealmHasNoAuthority.into());
    }
    if realm_data.authority.unwrap() != *realm_authority {
        return Err(GovernanceError::InvalidAuthorityForRealm.into());
    }
    Ok(realm_data)
}
pub fn get_realm_data_for_governing_token_mint(
    program_id: &Pubkey,
    realm_info: &AccountInfo,
    governing_token_mint: &Pubkey,
) -> Result<RealmV2, ProgramError> {
    let realm_data = get_realm_data(program_id, realm_info)?;
    realm_data.assert_is_valid_governing_token_mint(governing_token_mint)?;
    Ok(realm_data)
}
pub fn get_realm_address_seeds(name: &str) -> [&[u8]; 2] {
    [PROGRAM_AUTHORITY_SEED, name.as_bytes()]
}
pub fn get_realm_address(program_id: &Pubkey, name: &str) -> Pubkey {
    Pubkey::find_program_address(&get_realm_address_seeds(name), program_id).0
}
pub fn get_governing_token_holding_address_seeds<'a>(
    realm: &'a Pubkey,
    governing_token_mint: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        PROGRAM_AUTHORITY_SEED,
        realm.as_ref(),
        governing_token_mint.as_ref(),
    ]
}
pub fn get_governing_token_holding_address(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_mint: &Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_governing_token_holding_address_seeds(realm, governing_token_mint),
        program_id,
    )
    .0
}
pub fn assert_valid_realm_config_args(
    realm_config_args: &RealmConfigArgs,
) -> Result<(), ProgramError> {
    match realm_config_args.community_mint_max_voter_weight_source {
        MintMaxVoterWeightSource::SupplyFraction(fraction) => {
            if !(1..=MintMaxVoterWeightSource::SUPPLY_FRACTION_BASE).contains(&fraction) {
                return Err(GovernanceError::InvalidMaxVoterWeightSupplyFraction.into());
            }
        }
        MintMaxVoterWeightSource::Absolute(value) => {
            if value == 0 {
                return Err(GovernanceError::InvalidMaxVoterWeightAbsoluteValue.into());
            }
        }
    }
    Ok(())
}