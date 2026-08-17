use {
    crate::error::GovernanceToolsError,
    borsh::{BorshDeserialize, BorshSerialize},
    solana_program::{
        account_info::AccountInfo,
        borsh1::try_from_slice_unchecked,
        msg,
        program::{invoke, invoke_signed},
        program_error::ProgramError,
        program_pack::IsInitialized,
        pubkey::Pubkey,
        rent::Rent,
        system_instruction::{self, create_account},
        system_program,
        sysvar::Sysvar,
    },
};
pub trait AccountMaxSize {
    fn get_max_size(&self) -> Option<usize> {
        None
    }
}
pub fn create_and_serialize_account<'a, T: BorshSerialize + AccountMaxSize>(
    payer_info: &AccountInfo<'a>,
    account_info: &AccountInfo<'a>,
    account_data: &T,
    program_id: &Pubkey,
    system_info: &AccountInfo<'a>,
) -> Result<(), ProgramError> {
    if !(account_info.data_is_empty() && *account_info.owner == system_program::id()) {
        return Err(GovernanceToolsError::AccountAlreadyInitialized.into());
    }
    let (serialized_data, account_size) = if let Some(max_size) = account_data.get_max_size() {
        (None, max_size)
    } else {
        let serialized_data = borsh::to_vec(account_data)?;
        let account_size = serialized_data.len();
        (Some(serialized_data), account_size)
    };
    let rent = Rent::get()?;
    let create_account_instruction = create_account(
        payer_info.key,
        account_info.key,
        rent.minimum_balance(account_size),
        account_size as u64,
        program_id,
    );
    invoke(
        &create_account_instruction,
        &[
            payer_info.clone(),
            account_info.clone(),
            system_info.clone(),
        ],
    )?;
    if let Some(serialized_data) = serialized_data {
        account_info
            .data
            .borrow_mut()
            .copy_from_slice(&serialized_data);
    } else {
        borsh::to_writer(&mut account_info.data.borrow_mut()[..], account_data)?;
    }
    Ok(())
}
#[allow(clippy::too_many_arguments)]
pub fn create_and_serialize_account_signed<'a, T: BorshSerialize + AccountMaxSize>(
    payer_info: &AccountInfo<'a>,
    account_info: &AccountInfo<'a>,
    account_data: &T,
    account_address_seeds: &[&[u8]],
    program_id: &Pubkey,
    system_info: &AccountInfo<'a>,
    rent: &Rent,
    extra_lamports: u64,
) -> Result<(), ProgramError> {
    create_and_serialize_account_with_owner_signed(
        payer_info,
        account_info,
        account_data,
        account_address_seeds,
        program_id,
        program_id,
        system_info,
        rent,
        extra_lamports,
    )
}
#[allow(clippy::too_many_arguments)]
pub fn create_and_serialize_account_with_owner_signed<'a, T: BorshSerialize + AccountMaxSize>(
    payer_info: &AccountInfo<'a>,
    account_info: &AccountInfo<'a>,
    account_data: &T,
    account_address_seeds: &[&[u8]],
    program_id: &Pubkey,
    owner_program_id: &Pubkey,
    system_info: &AccountInfo<'a>,
    rent: &Rent,
    extra_lamports: u64,
) -> Result<(), ProgramError> {
    let (account_address, bump_seed) =
        Pubkey::find_program_address(account_address_seeds, program_id);
    if account_address != *account_info.key {
        msg!(
            "Create account with PDA: {:?} was requested while PDA: {:?} was expected",
            account_info.key,
            account_address
        );
        return Err(ProgramError::InvalidSeeds);
    }
    let (serialized_data, account_size) = if let Some(max_size) = account_data.get_max_size() {
        (None, max_size)
    } else {
        let serialized_data = borsh::to_vec(&account_data)?;
        let account_size = serialized_data.len();
        (Some(serialized_data), account_size)
    };
    let mut signers_seeds = account_address_seeds.to_vec();
    let bump = &[bump_seed];
    signers_seeds.push(bump);
    let rent_exempt_lamports = rent.minimum_balance(account_size);
    let total_lamports = rent_exempt_lamports.checked_add(extra_lamports).unwrap();
    if account_info.lamports() > 0 {
        let top_up_lamports = total_lamports.saturating_sub(account_info.lamports());
        if top_up_lamports > 0 {
            invoke(
                &system_instruction::transfer(payer_info.key, account_info.key, top_up_lamports),
                &[
                    payer_info.clone(),
                    account_info.clone(),
                    system_info.clone(),
                ],
            )?;
        }
        invoke_signed(
            &system_instruction::allocate(account_info.key, account_size as u64),
            &[account_info.clone(), system_info.clone()],
            &[&signers_seeds[..]],
        )?;
        invoke_signed(
            &system_instruction::assign(account_info.key, owner_program_id),
            &[account_info.clone(), system_info.clone()],
            &[&signers_seeds[..]],
        )?;
    } else {
        let create_account_instruction = create_account(
            payer_info.key,
            account_info.key,
            total_lamports,
            account_size as u64,
            owner_program_id,
        );
        invoke_signed(
            &create_account_instruction,
            &[
                payer_info.clone(),
                account_info.clone(),
                system_info.clone(),
            ],
            &[&signers_seeds[..]],
        )?;
    }
    if let Some(serialized_data) = serialized_data {
        account_info
            .data
            .borrow_mut()
            .copy_from_slice(&serialized_data);
    } else if account_size > 0 {
        borsh::to_writer(&mut account_info.data.borrow_mut()[..], account_data)?;
    }
    Ok(())
}
pub fn get_account_data<T: BorshDeserialize + IsInitialized>(
    owner_program_id: &Pubkey,
    account_info: &AccountInfo,
) -> Result<T, ProgramError> {
    if account_info.data_is_empty() {
        return Err(GovernanceToolsError::AccountDoesNotExist.into());
    }
    if account_info.owner != owner_program_id {
        return Err(GovernanceToolsError::InvalidAccountOwner.into());
    }
    let account: T = try_from_slice_unchecked(&account_info.data.borrow())?;
    if !account.is_initialized() {
        Err(ProgramError::UninitializedAccount)
    } else {
        Ok(account)
    }
}
pub fn get_account_type<T: BorshDeserialize>(
    owner_program_id: &Pubkey,
    account_info: &AccountInfo,
) -> Result<T, ProgramError> {
    if account_info.data_is_empty() {
        return Err(GovernanceToolsError::AccountDoesNotExist.into());
    }
    if account_info.owner != owner_program_id {
        return Err(GovernanceToolsError::InvalidAccountOwner.into());
    }
    let account_type: T = try_from_slice_unchecked(&account_info.data.borrow())?;
    Ok(account_type)
}
pub fn assert_is_valid_account_of_type<T: BorshDeserialize + PartialEq>(
    owner_program_id: &Pubkey,
    account_info: &AccountInfo,
    account_type: T,
) -> Result<(), ProgramError> {
    assert_is_valid_account_of_types(owner_program_id, account_info, |at: &T| *at == account_type)
}
pub fn assert_is_valid_account_of_types<T: BorshDeserialize + PartialEq, F: Fn(&T) -> bool>(
    owner_program_id: &Pubkey,
    account_info: &AccountInfo,
    is_account_type: F,
) -> Result<(), ProgramError> {
    if account_info.data_is_empty() {
        return Err(GovernanceToolsError::AccountDoesNotExist.into());
    }
    if account_info.owner != owner_program_id {
        return Err(GovernanceToolsError::InvalidAccountOwner.into());
    }
    let account_type: T = try_from_slice_unchecked(&account_info.data.borrow())?;
    if !is_account_type(&account_type) {
        return Err(GovernanceToolsError::InvalidAccountType.into());
    };
    Ok(())
}
pub fn dispose_account(
    account_info: &AccountInfo,
    beneficiary_info: &AccountInfo,
) -> Result<(), ProgramError> {
    let account_lamports = account_info.lamports();
    **account_info.lamports.borrow_mut() = 0;
    **beneficiary_info.lamports.borrow_mut() = beneficiary_info
        .lamports()
        .checked_add(account_lamports)
        .unwrap();
    account_info.assign(&system_program::id());
    account_info.realloc(0, false)
}
pub fn extend_account_size<'a>(
    account_info: &AccountInfo<'a>,
    payer_info: &AccountInfo<'a>,
    new_account_size: usize,
    rent: &Rent,
    system_info: &AccountInfo<'a>,
) -> Result<(), ProgramError> {
    if new_account_size <= account_info.data_len() {
        return Err(GovernanceToolsError::InvalidNewAccountSize.into());
    }
    let rent_exempt_lamports = rent.minimum_balance(new_account_size);
    let top_up_lamports = rent_exempt_lamports.saturating_sub(account_info.lamports());
    if top_up_lamports > 0 {
        invoke(
            &system_instruction::transfer(payer_info.key, account_info.key, top_up_lamports),
            &[
                payer_info.clone(),
                account_info.clone(),
                system_info.clone(),
            ],
        )?;
    }
    account_info.realloc(new_account_size, false)
}