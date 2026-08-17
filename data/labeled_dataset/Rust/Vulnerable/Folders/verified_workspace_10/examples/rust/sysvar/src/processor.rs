use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint::ProgramResult,
    msg,
    pubkey::Pubkey,
    sysvar::{clock::Clock, rent::Rent, Sysvar},
};
pub fn process_instruction(
    _program_id: &Pubkey,
    accounts: &[AccountInfo],
    _instruction_data: &[u8],
) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();
    let clock_via_sysvar = Clock::get()?;
    let clock_sysvar_info = next_account_info(account_info_iter)?;
    let clock_via_account = Clock::from_account_info(clock_sysvar_info)?;
    assert_eq!(clock_via_sysvar, clock_via_account);
    msg!("{:?}", clock_via_sysvar);
    let rent_via_sysvar = Rent::get()?;
    let rent_sysvar_info = next_account_info(account_info_iter)?;
    let rent_via_account = Rent::from_account_info(rent_sysvar_info)?;
    assert_eq!(rent_via_sysvar, rent_via_account);
    msg!(
        "Rent: lamports_per_byte_year: {:?}, burn_percent: {:?}",
        rent_via_sysvar.lamports_per_byte_year,
        rent_via_sysvar.burn_percent
    );
    Ok(())
}