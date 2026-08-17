use {
    crate::{
        addins::voter_weight::{
            assert_is_valid_voter_weight, get_voter_weight_record_data_for_token_owner_record,
        },
        error::GovernanceError,
        state::{
            enums::GovernanceAccountType, governance::GovernanceConfig, legacy::TokenOwnerRecordV1,
            realm::RealmV2, realm_config::RealmConfigAccount,
        },
        PROGRAM_AUTHORITY_SEED,
    },
    borsh::{io::Write, BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::{next_account_info, AccountInfo},
        clock::UnixTimestamp,
        program_error::ProgramError,
        program_pack::IsInitialized,
        pubkey::Pubkey,
        rent::Rent,
    },
    spl_governance_addin_api::voter_weight::VoterWeightAction,
    spl_governance_tools::account::{
        extend_account_size, get_account_data, get_account_type, AccountMaxSize,
    },
    std::slice::Iter,
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct TokenOwnerRecordLock {
    pub lock_id: u8,
    pub authority: Pubkey,
    pub expiry: Option<UnixTimestamp>,
}
impl TokenOwnerRecordLock {
    pub fn is_expired(&self, current_unix_timestamp: UnixTimestamp) -> bool {
        self.expiry.is_some() && Some(current_unix_timestamp) > self.expiry
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct TokenOwnerRecordV2 {
    pub account_type: GovernanceAccountType,
    pub realm: Pubkey,
    pub governing_token_mint: Pubkey,
    pub governing_token_owner: Pubkey,
    pub governing_token_deposit_amount: u64,
    pub unrelinquished_votes_count: u64,
    pub outstanding_proposal_count: u8,
    pub version: u8,
    pub reserved: [u8; 6],
    pub governance_delegate: Option<Pubkey>,
    pub reserved_v2: [u8; 124],
    pub locks: Vec<TokenOwnerRecordLock>,
}
pub const TOKEN_OWNER_RECORD_LAYOUT_VERSION: u8 = 1;
impl AccountMaxSize for TokenOwnerRecordV2 {
    fn get_max_size(&self) -> Option<usize> {
        Some(282 + self.locks.len() * 42)
    }
}
impl IsInitialized for TokenOwnerRecordV2 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::TokenOwnerRecordV2
    }
}
impl TokenOwnerRecordV2 {
    pub fn assert_token_owner_or_delegate_is_signer(
        &self,
        governance_authority_info: &AccountInfo,
    ) -> Result<(), ProgramError> {
        if governance_authority_info.is_signer {
            if &self.governing_token_owner == governance_authority_info.key {
                return Ok(());
            }
            if let Some(governance_delegate) = self.governance_delegate {
                if &governance_delegate == governance_authority_info.key {
                    return Ok(());
                }
            };
        }
        Err(GovernanceError::GoverningTokenOwnerOrDelegateMustSign.into())
    }
    pub fn assert_can_create_proposal(
        &self,
        realm_data: &RealmV2,
        config: &GovernanceConfig,
        voter_weight: u64,
    ) -> Result<(), ProgramError> {
        let min_weight_to_create_proposal =
            if self.governing_token_mint == realm_data.community_mint {
                config.min_community_weight_to_create_proposal
            } else if Some(self.governing_token_mint) == realm_data.config.council_mint {
                config.min_council_weight_to_create_proposal
            } else {
                return Err(GovernanceError::InvalidGoverningTokenMint.into());
            };
        if min_weight_to_create_proposal == u64::MAX {
            return Err(GovernanceError::VoterWeightThresholdDisabled.into());
        }
        if voter_weight < min_weight_to_create_proposal {
            return Err(GovernanceError::NotEnoughTokensToCreateProposal.into());
        }
        if self.outstanding_proposal_count >= 10 {
            return Err(GovernanceError::TooManyOutstandingProposals.into());
        }
        Ok(())
    }
    pub fn assert_can_create_governance(
        &self,
        realm_data: &RealmV2,
        voter_weight: u64,
    ) -> Result<(), ProgramError> {
        let min_weight_to_create_governance =
            if self.governing_token_mint == realm_data.community_mint {
                realm_data.config.min_community_weight_to_create_governance
            } else if Some(self.governing_token_mint) == realm_data.config.council_mint {
                1
            } else {
                return Err(GovernanceError::InvalidGoverningTokenMint.into());
            };
        if min_weight_to_create_governance == u64::MAX {
            return Err(GovernanceError::VoterWeightThresholdDisabled.into());
        }
        if voter_weight < min_weight_to_create_governance {
            return Err(GovernanceError::NotEnoughTokensToCreateGovernance.into());
        }
        Ok(())
    }
    pub fn assert_can_withdraw_governing_tokens(
        &self,
        current_unix_timestamp: UnixTimestamp,
    ) -> Result<(), ProgramError> {
        if self.unrelinquished_votes_count > 0 {
            return Err(
                GovernanceError::AllVotesMustBeRelinquishedToWithdrawGoverningTokens.into(),
            );
        }
        if self.outstanding_proposal_count > 0 {
            return Err(
                GovernanceError::AllProposalsMustBeFinalisedToWithdrawGoverningTokens.into(),
            );
        }
        if self
            .locks
            .iter()
            .any(|lock| !lock.is_expired(current_unix_timestamp))
        {
            return Err(GovernanceError::TokenOwnerRecordLocked.into());
        }
        Ok(())
    }
    pub fn decrease_outstanding_proposal_count(&mut self) {
        if self.outstanding_proposal_count != 0 {
            self.outstanding_proposal_count =
                self.outstanding_proposal_count.checked_sub(1).unwrap();
        }
    }
    #[allow(clippy::too_many_arguments)]
    pub fn resolve_voter_weight(
        &self,
        account_info_iter: &mut Iter<AccountInfo>,
        realm_data: &RealmV2,
        realm_config_data: &RealmConfigAccount,
        weight_action: VoterWeightAction,
        weight_action_target: &Pubkey,
    ) -> Result<u64, ProgramError> {
        if let Some(voter_weight_addin) = realm_config_data
            .get_token_config(realm_data, &self.governing_token_mint)?
            .voter_weight_addin
        {
            let voter_weight_record_info = next_account_info(account_info_iter)?;
            let voter_weight_record_data = get_voter_weight_record_data_for_token_owner_record(
                &voter_weight_addin,
                voter_weight_record_info,
                self,
            )?;
            assert_is_valid_voter_weight(
                &voter_weight_record_data,
                weight_action,
                weight_action_target,
            )?;
            Ok(voter_weight_record_data.voter_weight)
        } else {
            Ok(self.governing_token_deposit_amount)
        }
    }
    pub fn remove_expired_locks(&mut self, current_unix_timestamp: UnixTimestamp) {
        self.locks
            .retain(|lock| !lock.is_expired(current_unix_timestamp));
    }
    pub fn remove_lock(
        &mut self,
        lock_id: u8,
        lock_authority: &Pubkey,
    ) -> Result<(), ProgramError> {
        if let Some(lock_index) = self
            .locks
            .iter()
            .position(|lock| lock.lock_id == lock_id && lock.authority == *lock_authority)
        {
            self.locks.remove(lock_index);
            Ok(())
        } else {
            Err(GovernanceError::TokenOwnerRecordLockNotFound.into())
        }
    }
    pub fn upsert_lock(&mut self, lock: TokenOwnerRecordLock) {
        if let Some(lock_index) = self.locks.iter().position(|existing_lock| {
            existing_lock.lock_id == lock.lock_id && existing_lock.authority == lock.authority
        }) {
            self.locks[lock_index] = lock;
        } else {
            self.locks.push(lock);
        }
    }
    pub fn serialize_with_resize<'a>(
        mut self,
        token_owner_record_info: &AccountInfo<'a>,
        payer_info: &AccountInfo<'a>,
        system_info: &AccountInfo<'a>,
        rent: &Rent,
    ) -> Result<(), ProgramError> {
        let token_owner_record_data_max_size = self.get_max_size().unwrap();
        if token_owner_record_info.data_len() < token_owner_record_data_max_size {
            extend_account_size(
                token_owner_record_info,
                payer_info,
                token_owner_record_data_max_size,
                rent,
                system_info,
            )?;
            if self.account_type == GovernanceAccountType::TokenOwnerRecordV1 {
                self.account_type = GovernanceAccountType::TokenOwnerRecordV2;
            }
        }
        self.serialize(&mut token_owner_record_info.data.borrow_mut()[..])
    }
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if self.account_type == GovernanceAccountType::TokenOwnerRecordV2 {
            borsh::to_writer(writer, &self)?
        } else if self.account_type == GovernanceAccountType::TokenOwnerRecordV1 {
            if self.reserved_v2 != [0; 124] {
                panic!("Extended data not supported by TokenOwnerRecordV1")
            }
            let token_owner_record_data_v1 = TokenOwnerRecordV1 {
                account_type: self.account_type,
                realm: self.realm,
                governing_token_mint: self.governing_token_mint,
                governing_token_owner: self.governing_token_owner,
                governing_token_deposit_amount: self.governing_token_deposit_amount,
                unrelinquished_votes_count: self.unrelinquished_votes_count,
                outstanding_proposal_count: self.outstanding_proposal_count,
                version: self.version,
                reserved: self.reserved,
                governance_delegate: self.governance_delegate,
            };
            borsh::to_writer(writer, &token_owner_record_data_v1)?
        }
        Ok(())
    }
}
pub fn get_token_owner_record_address(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_mint: &Pubkey,
    governing_token_owner: &Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_token_owner_record_address_seeds(realm, governing_token_mint, governing_token_owner),
        program_id,
    )
    .0
}
pub fn get_token_owner_record_address_seeds<'a>(
    realm: &'a Pubkey,
    governing_token_mint: &'a Pubkey,
    governing_token_owner: &'a Pubkey,
) -> [&'a [u8]; 4] {
    [
        PROGRAM_AUTHORITY_SEED,
        realm.as_ref(),
        governing_token_mint.as_ref(),
        governing_token_owner.as_ref(),
    ]
}
pub fn get_token_owner_record_data(
    program_id: &Pubkey,
    token_owner_record_info: &AccountInfo,
) -> Result<TokenOwnerRecordV2, ProgramError> {
    let account_type: GovernanceAccountType =
        get_account_type(program_id, token_owner_record_info)?;
    let mut token_owner_record_data = if account_type == GovernanceAccountType::TokenOwnerRecordV1 {
        let token_owner_record_data_v1 =
            get_account_data::<TokenOwnerRecordV1>(program_id, token_owner_record_info)?;
        TokenOwnerRecordV2 {
            account_type,
            realm: token_owner_record_data_v1.realm,
            governing_token_mint: token_owner_record_data_v1.governing_token_mint,
            governing_token_owner: token_owner_record_data_v1.governing_token_owner,
            governing_token_deposit_amount: token_owner_record_data_v1
                .governing_token_deposit_amount,
            unrelinquished_votes_count: token_owner_record_data_v1.unrelinquished_votes_count,
            outstanding_proposal_count: token_owner_record_data_v1.outstanding_proposal_count,
            version: token_owner_record_data_v1.version,
            reserved: token_owner_record_data_v1.reserved,
            governance_delegate: token_owner_record_data_v1.governance_delegate,
            reserved_v2: [0; 124],
            locks: vec![],
        }
    } else {
        get_account_data::<TokenOwnerRecordV2>(program_id, token_owner_record_info)?
    };
    if token_owner_record_data.version < 1 {
        token_owner_record_data.version = 1;
        token_owner_record_data.unrelinquished_votes_count &= u32::MAX as u64;
    }
    Ok(token_owner_record_data)
}
pub fn get_token_owner_record_data_for_seeds(
    program_id: &Pubkey,
    token_owner_record_info: &AccountInfo,
    token_owner_record_seeds: &[&[u8]],
) -> Result<TokenOwnerRecordV2, ProgramError> {
    let (token_owner_record_address, _) =
        Pubkey::find_program_address(token_owner_record_seeds, program_id);
    if token_owner_record_address != *token_owner_record_info.key {
        return Err(GovernanceError::InvalidTokenOwnerRecordAccountAddress.into());
    }
    get_token_owner_record_data(program_id, token_owner_record_info)
}
pub fn get_token_owner_record_data_for_realm(
    program_id: &Pubkey,
    token_owner_record_info: &AccountInfo,
    realm: &Pubkey,
) -> Result<TokenOwnerRecordV2, ProgramError> {
    let token_owner_record_data = get_token_owner_record_data(program_id, token_owner_record_info)?;
    if token_owner_record_data.realm != *realm {
        return Err(GovernanceError::InvalidRealmForTokenOwnerRecord.into());
    }
    Ok(token_owner_record_data)
}
pub fn get_token_owner_record_data_for_realm_and_governing_mint(
    program_id: &Pubkey,
    token_owner_record_info: &AccountInfo,
    realm: &Pubkey,
    governing_token_mint: &Pubkey,
) -> Result<TokenOwnerRecordV2, ProgramError> {
    let token_owner_record_data =
        get_token_owner_record_data_for_realm(program_id, token_owner_record_info, realm)?;
    if token_owner_record_data.governing_token_mint != *governing_token_mint {
        return Err(GovernanceError::InvalidGoverningMintForTokenOwnerRecord.into());
    }
    Ok(token_owner_record_data)
}
pub fn get_token_owner_record_data_for_proposal_owner(
    program_id: &Pubkey,
    token_owner_record_info: &AccountInfo,
    proposal_owner: &Pubkey,
) -> Result<TokenOwnerRecordV2, ProgramError> {
    if token_owner_record_info.key != proposal_owner {
        return Err(GovernanceError::InvalidProposalOwnerAccount.into());
    }
    get_token_owner_record_data(program_id, token_owner_record_info)
}