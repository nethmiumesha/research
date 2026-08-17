use {
    crate::get_token_upgrade_authority_address,
    num_enum::{IntoPrimitive, TryFromPrimitive},
    solana_program::{
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
    },
};
#[derive(Clone, Copy, Debug, TryFromPrimitive, IntoPrimitive)]
#[repr(u8)]
pub enum TokenUpgradeInstruction {
    Exchange,
}
#[allow(clippy::too_many_arguments)]
pub fn exchange(
    program_id: &Pubkey,
    original_account: &Pubkey,
    original_mint: &Pubkey,
    new_escrow: &Pubkey,
    new_account: &Pubkey,
    new_mint: &Pubkey,
    original_token_program_id: &Pubkey,
    new_token_program_id: &Pubkey,
    original_transfer_authority: &Pubkey,
    original_multisig_signers: &[&Pubkey],
) -> Instruction {
    let escrow_authority = get_token_upgrade_authority_address(original_mint, new_mint, program_id);
    let mut accounts = Vec::with_capacity(9usize.saturating_add(original_multisig_signers.len()));
    accounts.push(AccountMeta::new(*original_account, false));
    accounts.push(AccountMeta::new(*original_mint, false));
    accounts.push(AccountMeta::new(*new_escrow, false));
    accounts.push(AccountMeta::new(*new_account, false));
    accounts.push(AccountMeta::new(*new_mint, false));
    accounts.push(AccountMeta::new_readonly(escrow_authority, false));
    accounts.push(AccountMeta::new_readonly(*original_token_program_id, false));
    accounts.push(AccountMeta::new_readonly(*new_token_program_id, false));
    accounts.push(AccountMeta::new_readonly(
        *original_transfer_authority,
        original_multisig_signers.is_empty(),
    ));
    for signer_pubkey in original_multisig_signers.iter() {
        accounts.push(AccountMeta::new_readonly(**signer_pubkey, true));
    }
    Instruction {
        program_id: *program_id,
        accounts,
        data: vec![TokenUpgradeInstruction::Exchange.into()],
    }
}