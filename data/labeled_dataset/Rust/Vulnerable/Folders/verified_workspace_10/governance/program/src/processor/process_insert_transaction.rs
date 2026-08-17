use {
    crate::{
        error::GovernanceError,
        state::{
            enums::{GovernanceAccountType, TransactionExecutionStatus},
            governance::get_governance_data,
            proposal::get_proposal_data_for_governance,
            proposal_transaction::{
                get_proposal_transaction_address_seeds, InstructionData, ProposalTransactionV2,
            },
            token_owner_record::get_token_owner_record_data_for_proposal_owner,
        },
    },
    solana_program::{
        account_info::{next_account_info, AccountInfo},
        entrypoint::ProgramResult,
        pubkey::Pubkey,
        rent::Rent,
        sysvar::Sysvar,
    },
    spl_governance_tools::account::create_and_serialize_account_signed,
    std::cmp::Ordering,
};
pub fn process_insert_transaction(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    option_index: u8,
    instruction_index: u16,
    instructions: Vec<InstructionData>,
) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();
    let governance_info = next_account_info(account_info_iter)?;
    let proposal_info = next_account_info(account_info_iter)?;
    let token_owner_record_info = next_account_info(account_info_iter)?;
    let governance_authority_info = next_account_info(account_info_iter)?;
    let proposal_transaction_info = next_account_info(account_info_iter)?;
    let payer_info = next_account_info(account_info_iter)?;
    let system_info = next_account_info(account_info_iter)?;
    let rent_sysvar_info = next_account_info(account_info_iter)?;
    let rent = &Rent::from_account_info(rent_sysvar_info)?;
    if !proposal_transaction_info.data_is_empty() {
        return Err(GovernanceError::TransactionAlreadyExists.into());
    }
    let _governance_data = get_governance_data(program_id, governance_info)?;
    let mut proposal_data =
        get_proposal_data_for_governance(program_id, proposal_info, governance_info.key)?;
    proposal_data.assert_can_edit_instructions()?;
    let token_owner_record_data = get_token_owner_record_data_for_proposal_owner(
        program_id,
        token_owner_record_info,
        &proposal_data.token_owner_record,
    )?;
    token_owner_record_data.assert_token_owner_or_delegate_is_signer(governance_authority_info)?;
    let option = &mut proposal_data.options[option_index as usize];
    match instruction_index.cmp(&option.transactions_next_index) {
        Ordering::Greater => return Err(GovernanceError::InvalidTransactionIndex.into()),
        Ordering::Equal => {
            option.transactions_next_index = option.transactions_next_index.checked_add(1).unwrap();
        }
        Ordering::Less => {}
    }
    option.transactions_count = option.transactions_count.checked_add(1).unwrap();
    proposal_data.serialize(&mut proposal_info.data.borrow_mut()[..])?;
    let proposal_transaction_data = ProposalTransactionV2 {
        account_type: GovernanceAccountType::ProposalTransactionV2,
        option_index,
        transaction_index: instruction_index,
        legacy: 0,
        instructions,
        executed_at: None,
        execution_status: TransactionExecutionStatus::None,
        proposal: *proposal_info.key,
        reserved_v2: [0; 8],
    };
    create_and_serialize_account_signed::<ProposalTransactionV2>(
        payer_info,
        proposal_transaction_info,
        &proposal_transaction_data,
        &get_proposal_transaction_address_seeds(
            proposal_info.key,
            &option_index.to_le_bytes(),
            &instruction_index.to_le_bytes(),
        ),
        program_id,
        system_info,
        rent,
        0,
    )?;
    Ok(())
}