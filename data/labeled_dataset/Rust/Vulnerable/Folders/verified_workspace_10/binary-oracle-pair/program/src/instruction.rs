use {
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{
        clock::Slot,
        instruction::{AccountMeta, Instruction},
        program_error::ProgramError,
        pubkey::Pubkey,
        sysvar,
    },
};
#[repr(C)]
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct InitArgs {
    pub mint_end_slot: Slot,
    pub decide_end_slot: Slot,
    pub bump_seed: u8,
}
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub enum PoolInstruction {
    InitPool(InitArgs),
    Deposit(u64),
    Withdraw(u64),
    Decide(bool),
}
#[allow(clippy::too_many_arguments)]
pub fn init_pool(
    program_id: &Pubkey,
    pool: &Pubkey,
    authority: &Pubkey,
    decider: &Pubkey,
    deposit_token_mint: &Pubkey,
    deposit_account: &Pubkey,
    token_pass_mint: &Pubkey,
    token_fail_mint: &Pubkey,
    token_program_id: &Pubkey,
    init_args: InitArgs,
) -> Result<Instruction, ProgramError> {
    let init_data = PoolInstruction::InitPool(init_args);
    let data = borsh::to_vec(&init_data)?;
    let accounts = vec![
        AccountMeta::new(*pool, false),
        AccountMeta::new_readonly(*authority, false),
        AccountMeta::new_readonly(*decider, false),
        AccountMeta::new_readonly(*deposit_token_mint, false),
        AccountMeta::new(*deposit_account, false),
        AccountMeta::new(*token_pass_mint, false),
        AccountMeta::new(*token_fail_mint, false),
        AccountMeta::new_readonly(sysvar::rent::id(), false),
        AccountMeta::new_readonly(*token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
#[allow(clippy::too_many_arguments)]
pub fn deposit(
    program_id: &Pubkey,
    pool: &Pubkey,
    authority: &Pubkey,
    user_transfer_authority: &Pubkey,
    user_token_account: &Pubkey,
    pool_deposit_token_account: &Pubkey,
    token_pass_mint: &Pubkey,
    token_fail_mint: &Pubkey,
    token_pass_destination_account: &Pubkey,
    token_fail_destination_account: &Pubkey,
    token_program_id: &Pubkey,
    amount: u64,
) -> Result<Instruction, ProgramError> {
    let init_data = PoolInstruction::Deposit(amount);
    let data = borsh::to_vec(&init_data)?;
    let accounts = vec![
        AccountMeta::new_readonly(*pool, false),
        AccountMeta::new_readonly(*authority, false),
        AccountMeta::new_readonly(
            *user_transfer_authority,
            authority != user_transfer_authority,
        ),
        AccountMeta::new(*user_token_account, false),
        AccountMeta::new(*pool_deposit_token_account, false),
        AccountMeta::new(*token_pass_mint, false),
        AccountMeta::new(*token_fail_mint, false),
        AccountMeta::new(*token_pass_destination_account, false),
        AccountMeta::new(*token_fail_destination_account, false),
        AccountMeta::new_readonly(sysvar::clock::id(), false),
        AccountMeta::new_readonly(*token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
#[allow(clippy::too_many_arguments)]
pub fn withdraw(
    program_id: &Pubkey,
    pool: &Pubkey,
    authority: &Pubkey,
    user_transfer_authority: &Pubkey,
    pool_deposit_token_account: &Pubkey,
    token_pass_user_account: &Pubkey,
    token_fail_user_account: &Pubkey,
    token_pass_mint: &Pubkey,
    token_fail_mint: &Pubkey,
    user_token_destination_account: &Pubkey,
    token_program_id: &Pubkey,
    amount: u64,
) -> Result<Instruction, ProgramError> {
    let init_data = PoolInstruction::Withdraw(amount);
    let data = borsh::to_vec(&init_data)?;
    let accounts = vec![
        AccountMeta::new_readonly(*pool, false),
        AccountMeta::new_readonly(*authority, false),
        AccountMeta::new_readonly(
            *user_transfer_authority,
            authority != user_transfer_authority,
        ),
        AccountMeta::new(*pool_deposit_token_account, false),
        AccountMeta::new(*token_pass_user_account, false),
        AccountMeta::new(*token_fail_user_account, false),
        AccountMeta::new(*token_pass_mint, false),
        AccountMeta::new(*token_fail_mint, false),
        AccountMeta::new(*user_token_destination_account, false),
        AccountMeta::new_readonly(sysvar::clock::id(), false),
        AccountMeta::new_readonly(*token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn decide(
    program_id: &Pubkey,
    pool: &Pubkey,
    decider: &Pubkey,
    decision: bool,
) -> Result<Instruction, ProgramError> {
    let init_data = PoolInstruction::Decide(decision);
    let data = borsh::to_vec(&init_data)?;
    let accounts = vec![
        AccountMeta::new(*pool, false),
        AccountMeta::new_readonly(*decider, true),
        AccountMeta::new_readonly(sysvar::clock::id(), false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}