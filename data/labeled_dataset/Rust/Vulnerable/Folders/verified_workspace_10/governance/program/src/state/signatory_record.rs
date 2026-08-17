use {
    crate::{
        error::GovernanceError,
        state::{enums::GovernanceAccountType, legacy::SignatoryRecordV1},
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
pub struct SignatoryRecordV2 {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub signatory: Pubkey,
    pub signed_off: bool,
    pub reserved_v2: [u8; 8],
}
impl AccountMaxSize for SignatoryRecordV2 {}
impl IsInitialized for SignatoryRecordV2 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::SignatoryRecordV2
    }
}
impl SignatoryRecordV2 {
    pub fn assert_can_sign_off(&self, signatory_info: &AccountInfo) -> Result<(), ProgramError> {
        if self.signed_off {
            return Err(GovernanceError::SignatoryAlreadySignedOff.into());
        }
        if !signatory_info.is_signer {
            return Err(GovernanceError::SignatoryMustSign.into());
        }
        Ok(())
    }
    pub fn assert_can_remove_signatory(&self) -> Result<(), ProgramError> {
        if self.signed_off {
            return Err(GovernanceError::SignatoryAlreadySignedOff.into());
        }
        Ok(())
    }
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if self.account_type == GovernanceAccountType::SignatoryRecordV2 {
            borsh::to_writer(writer, &self)?
        } else if self.account_type == GovernanceAccountType::SignatoryRecordV1 {
            if self.reserved_v2 != [0; 8] {
                panic!("Extended data not supported by SignatoryRecordV1")
            }
            let signatory_record_data_v1 = SignatoryRecordV1 {
                account_type: self.account_type,
                proposal: self.proposal,
                signatory: self.signatory,
                signed_off: self.signed_off,
            };
            borsh::to_writer(writer, &signatory_record_data_v1)?
        }
        Ok(())
    }
}
pub fn get_signatory_record_address_seeds<'a>(
    proposal: &'a Pubkey,
    signatory: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        PROGRAM_AUTHORITY_SEED,
        proposal.as_ref(),
        signatory.as_ref(),
    ]
}
pub fn get_signatory_record_address<'a>(
    program_id: &Pubkey,
    proposal: &'a Pubkey,
    signatory: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_signatory_record_address_seeds(proposal, signatory),
        program_id,
    )
    .0
}
pub fn get_signatory_record_data(
    program_id: &Pubkey,
    signatory_record_info: &AccountInfo,
) -> Result<SignatoryRecordV2, ProgramError> {
    let account_type: GovernanceAccountType = get_account_type(program_id, signatory_record_info)?;
    if account_type == GovernanceAccountType::SignatoryRecordV1 {
        let signatory_record_data_v1 =
            get_account_data::<SignatoryRecordV1>(program_id, signatory_record_info)?;
        return Ok(SignatoryRecordV2 {
            account_type,
            proposal: signatory_record_data_v1.proposal,
            signatory: signatory_record_data_v1.signatory,
            signed_off: signatory_record_data_v1.signed_off,
            reserved_v2: [0; 8],
        });
    }
    get_account_data::<SignatoryRecordV2>(program_id, signatory_record_info)
}
pub fn get_signatory_record_data_for_seeds(
    program_id: &Pubkey,
    signatory_record_info: &AccountInfo,
    proposal: &Pubkey,
    signatory: &Pubkey,
) -> Result<SignatoryRecordV2, ProgramError> {
    let (signatory_record_address, _) = Pubkey::find_program_address(
        &get_signatory_record_address_seeds(proposal, signatory),
        program_id,
    );
    if signatory_record_address != *signatory_record_info.key {
        return Err(GovernanceError::InvalidSignatoryAddress.into());
    }
    get_signatory_record_data(program_id, signatory_record_info)
}