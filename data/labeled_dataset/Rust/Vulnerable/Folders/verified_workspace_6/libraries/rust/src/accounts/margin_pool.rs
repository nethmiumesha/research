use solana_sdk::pubkey::Pubkey;
pub struct MarginPoolAccounts {
    pub address: Pubkey,
    pub token_mint: Pubkey,
    pub vault: Pubkey,
    pub deposit_note_mint: Pubkey,
    pub loan_note_mint: Pubkey,
}
impl MarginPoolAccounts {
    pub fn derive_from_token(token_mint: Pubkey) -> MarginPoolAccounts {
        let (address, _) =
            Pubkey::find_program_address(&[token_mint.as_ref()], &jet_margin_pool::id());
        let (vault, _) = Pubkey::find_program_address(
            &[address.as_ref(), b"vault".as_ref()],
            &jet_margin_pool::id(),
        );
        let (deposit_note_mint, _) = Pubkey::find_program_address(
            &[address.as_ref(), b"deposit-notes".as_ref()],
            &jet_margin_pool::id(),
        );
        let (loan_note_mint, _) = Pubkey::find_program_address(
            &[address.as_ref(), b"loan-notes".as_ref()],
            &jet_margin_pool::id(),
        );
        Self {
            token_mint,
            address,
            vault,
            deposit_note_mint,
            loan_note_mint,
        }
    }
}