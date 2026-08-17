use solana_sdk::pubkey::Pubkey;
pub fn get_metadata_address(address: &Pubkey) -> Pubkey {
    Pubkey::find_program_address(&[address.as_ref()], &jet_metadata::ID).0
}