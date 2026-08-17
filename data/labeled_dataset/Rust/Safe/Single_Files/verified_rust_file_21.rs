use {
    crate::{error::GovernanceError, state::enums::GovernanceAccountType},
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::AccountInfo, program_error::ProgramError, program_pack::IsInitialized,
        pubkey::Pubkey,
    },
    spl_governance_tools::account::{get_account_data, AccountMaxSize},
};
#[derive(Clone, Debug, PartialEq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct RequiredSignatory {
    pub account_type: GovernanceAccountType,
    pub account_version: u8,
    pub governance: Pubkey,
    pub signatory: Pubkey,
}
impl AccountMaxSize for RequiredSignatory {}
impl IsInitialized for RequiredSignatory {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::RequiredSignatory
    }
}
pub fn get_required_signatory_data_for_governance(
    program_id: &Pubkey,
    required_signatory_info: &AccountInfo,
    governance: &Pubkey,
) -> Result<RequiredSignatory, ProgramError> {
    let required_signatory_data =
        get_account_data::<RequiredSignatory>(program_id, required_signatory_info)?;
    if required_signatory_data.governance != *governance {
        return Err(GovernanceError::InvalidGovernanceForRequiredSignatory.into());
    }
    Ok(required_signatory_data)
}
pub fn get_required_signatory_address_seeds<'a>(
    governance: &'a Pubkey,
    signatory: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        b"required-signatory".as_ref(),
        governance.as_ref(),
        signatory.as_ref(),
    ]
}
pub fn get_required_signatory_address<'a>(
    program_id: &Pubkey,
    governance: &'a Pubkey,
    signatory: &'a Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_required_signatory_address_seeds(governance, signatory),
        program_id,
    )
    .0
}