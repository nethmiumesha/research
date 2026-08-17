use {
    crate::state::enums::GovernanceAccountType,
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::AccountInfo, clock::Slot, program_error::ProgramError,
        program_pack::IsInitialized, pubkey::Pubkey,
    },
    spl_governance_tools::account::{get_account_data, AccountMaxSize},
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProgramMetadata {
    pub account_type: GovernanceAccountType,
    pub updated_at: Slot,
    pub version: String,
    pub reserved: [u8; 64],
}
impl AccountMaxSize for ProgramMetadata {
    fn get_max_size(&self) -> Option<usize> {
        Some(88)
    }
}
impl IsInitialized for ProgramMetadata {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::ProgramMetadata
    }
}
pub fn get_program_metadata_address(program_id: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(&get_program_metadata_seeds(), program_id).0
}
pub fn get_program_metadata_seeds<'a>() -> [&'a [u8]; 1] {
    [b"metadata"]
}
pub fn get_program_metadata_data(
    program_id: &Pubkey,
    program_metadata_info: &AccountInfo,
) -> Result<ProgramMetadata, ProgramError> {
    get_account_data::<ProgramMetadata>(program_id, program_metadata_info)
}