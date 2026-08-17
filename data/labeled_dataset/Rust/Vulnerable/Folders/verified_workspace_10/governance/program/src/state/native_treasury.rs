use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::pubkey::Pubkey,
    spl_governance_tools::account::AccountMaxSize,
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct NativeTreasury {}
impl AccountMaxSize for NativeTreasury {
    fn get_max_size(&self) -> Option<usize> {
        Some(0)
    }
}
pub fn get_native_treasury_address_seeds(governance: &Pubkey) -> [&[u8]; 2] {
    [b"native-treasury", governance.as_ref()]
}
pub fn get_native_treasury_address(program_id: &Pubkey, governance: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(&get_native_treasury_address_seeds(governance), program_id).0
}