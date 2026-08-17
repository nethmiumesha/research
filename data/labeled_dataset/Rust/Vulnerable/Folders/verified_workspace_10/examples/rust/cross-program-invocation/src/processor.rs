use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint::ProgramResult,
    program::invoke_signed,
    program_error::ProgramError,
    pubkey::Pubkey,
    system_instruction,
};
pub const SIZE: usize = 42;
pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    instruction_data: &[u8],
) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();
    let system_program_info = next_account_info(account_info_iter)?;
    let allocated_info = next_account_info(account_info_iter)?;
    let expected_allocated_key =
        Pubkey::create_program_address(&[b"You pass butter", &[instruction_data[0]]], program_id)?;
    if *allocated_info.key != expected_allocated_key {
        return Err(ProgramError::InvalidArgument);
    }
    invoke_signed(
        &system_instruction::allocate(allocated_info.key, SIZE as u64),
        &[
            system_program_info.clone(),
            allocated_info.clone(),
        ],
        &[&[b"You pass butter", &[instruction_data[0]]]],
    )?;
    Ok(())
}