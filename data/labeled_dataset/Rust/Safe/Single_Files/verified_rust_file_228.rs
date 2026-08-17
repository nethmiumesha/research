use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    log::{sol_log_compute_units, sol_log_params, sol_log_slice},
    msg,
    pubkey::Pubkey,
};
pub fn process_instruction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    instruction_data: &[u8],
) -> ProgramResult {
    msg!("static string");
    sol_log_slice(instruction_data);
    msg!("formatted {}: {:?}", "message", instruction_data);
    program_id.log();
    sol_log_params(accounts, instruction_data);
    sol_log_compute_units();
    Ok(())
}