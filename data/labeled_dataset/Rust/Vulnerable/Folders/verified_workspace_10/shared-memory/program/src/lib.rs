#![allow(clippy::arithmetic_side_effects)]
#![deny(missing_docs)]
extern crate solana_program;
use {
    arrayref::{array_refs, mut_array_refs},
    solana_program::{
        declare_id,
        entrypoint::{MAX_PERMITTED_DATA_INCREASE, SUCCESS},
        program_error::ProgramError,
        pubkey::Pubkey,
    },
    std::{
        mem::{align_of, size_of},
        ptr::read,
        slice::{from_raw_parts, from_raw_parts_mut},
    },
};
declare_id!("shmem4EWT2sPdVGvTZCzXXRAURL9G5vpPxNwSeKhHUL");
fn fast_copy(mut src: &[u8], mut dst: &mut [u8]) {
    while src.len() >= 8 {
        #[allow(clippy::ptr_offset_with_cast)]
        let (src_word, src_rem) = array_refs![src, 8; ..;];
        #[allow(clippy::ptr_offset_with_cast)]
        let (dst_word, dst_rem) = mut_array_refs![dst, 8; ..;];
        *dst_word = *src_word;
        src = src_rem;
        dst = dst_rem;
    }
    unsafe {
        std::ptr::copy_nonoverlapping(src.as_ptr(), dst.as_mut_ptr(), src.len());
    }
}
unsafe fn deserialize_input_parameters<'a>(
    input: *mut u8,
) -> Result<(&'a mut [u8], &'a [u8]), u64> {
    let num_accounts = read(input as *const u64);
    if num_accounts == 0 {
        return Err(ProgramError::NotEnoughAccountKeys.into());
    } else if num_accounts > 1 {
        return Err(ProgramError::InvalidArgument.into());
    }
    let data_len_offset = size_of::<u64>()
        + size_of::<u8>()
        + size_of::<u8>()
        + size_of::<u8>()
        + size_of::<u8>()
        + size_of::<u32>()
        + size_of::<Pubkey>()
        + size_of::<Pubkey>()
        + size_of::<u64>();
    let account_data_len = read(input.add(data_len_offset) as *const usize);
    let data_ptr = input.add(data_len_offset + size_of::<u64>());
    let account_data = from_raw_parts_mut(data_ptr, account_data_len);
    let instruction_len_offset = account_data_len
        + MAX_PERMITTED_DATA_INCREASE
        + (account_data_len as *const u8).align_offset(align_of::<u128>())
        + size_of::<u64>();
    let instruction_data_len = read(data_ptr.add(instruction_len_offset) as *const usize);
    let instruction_data = from_raw_parts(
        data_ptr.add(instruction_len_offset + size_of::<u64>()),
        instruction_data_len,
    );
    Ok((account_data, instruction_data))
}
#[no_mangle]
pub unsafe extern "C" fn entrypoint(input: *mut u8) -> u64 {
    match deserialize_input_parameters(input) {
        Ok((account_data, instruction_data)) => {
            if instruction_data.len() < 8 {
                return ProgramError::AccountDataTooSmall.into();
            }
            #[allow(clippy::ptr_offset_with_cast)]
            let (offset, content) = array_refs![instruction_data, 8; ..;];
            let offset = usize::from_le_bytes(*offset);
            if account_data.len() < offset + content.len() {
                return ProgramError::AccountDataTooSmall.into();
            }
            let data_ptr = account_data.as_mut_ptr() as usize;
            let data = from_raw_parts_mut((data_ptr + offset) as *mut u8, content.len());
            fast_copy(content, data);
        }
        Err(err) => return err,
    }
    SUCCESS
}