#![allow(clippy::too_many_arguments)]
#[cfg(feature = "fuzz")]
use arbitrary::Arbitrary;
use {
    crate::{
        curve::{base::SwapCurve, fees::Fees},
        error::SwapError,
    },
    solana_program::{
        instruction::{AccountMeta, Instruction},
        program_error::ProgramError,
        program_pack::Pack,
        pubkey::Pubkey,
    },
    std::{convert::TryInto, mem::size_of},
};
#[repr(C)]
#[derive(Debug, PartialEq)]
pub struct Initialize {
    pub fees: Fees,
    pub swap_curve: SwapCurve,
}
#[cfg_attr(feature = "fuzz", derive(Arbitrary))]
#[repr(C)]
#[derive(Clone, Debug, PartialEq)]
pub struct Swap {
    pub amount_in: u64,
    pub minimum_amount_out: u64,
}
#[cfg_attr(feature = "fuzz", derive(Arbitrary))]
#[repr(C)]
#[derive(Clone, Debug, PartialEq)]
pub struct DepositAllTokenTypes {
    pub pool_token_amount: u64,
    pub maximum_token_a_amount: u64,
    pub maximum_token_b_amount: u64,
}
#[cfg_attr(feature = "fuzz", derive(Arbitrary))]
#[repr(C)]
#[derive(Clone, Debug, PartialEq)]
pub struct WithdrawAllTokenTypes {
    pub pool_token_amount: u64,
    pub minimum_token_a_amount: u64,
    pub minimum_token_b_amount: u64,
}
#[cfg_attr(feature = "fuzz", derive(Arbitrary))]
#[repr(C)]
#[derive(Clone, Debug, PartialEq)]
pub struct DepositSingleTokenTypeExactAmountIn {
    pub source_token_amount: u64,
    pub minimum_pool_token_amount: u64,
}
#[cfg_attr(feature = "fuzz", derive(Arbitrary))]
#[repr(C)]
#[derive(Clone, Debug, PartialEq)]
pub struct WithdrawSingleTokenTypeExactAmountOut {
    pub destination_token_amount: u64,
    pub maximum_pool_token_amount: u64,
}
#[repr(C)]
#[derive(Debug, PartialEq)]
pub enum SwapInstruction {
    Initialize(Initialize),
    Swap(Swap),
    DepositAllTokenTypes(DepositAllTokenTypes),
    WithdrawAllTokenTypes(WithdrawAllTokenTypes),
    DepositSingleTokenTypeExactAmountIn(DepositSingleTokenTypeExactAmountIn),
    WithdrawSingleTokenTypeExactAmountOut(WithdrawSingleTokenTypeExactAmountOut),
}
impl SwapInstruction {
    pub fn unpack(input: &[u8]) -> Result<Self, ProgramError> {
        let (&tag, rest) = input.split_first().ok_or(SwapError::InvalidInstruction)?;
        Ok(match tag {
            0 => {
                if rest.len() >= Fees::LEN {
                    let (fees, rest) = rest.split_at(Fees::LEN);
                    let fees = Fees::unpack_unchecked(fees)?;
                    let swap_curve = SwapCurve::unpack_unchecked(rest)?;
                    Self::Initialize(Initialize { fees, swap_curve })
                } else {
                    return Err(SwapError::InvalidInstruction.into());
                }
            }
            1 => {
                let (amount_in, rest) = Self::unpack_u64(rest)?;
                let (minimum_amount_out, _rest) = Self::unpack_u64(rest)?;
                Self::Swap(Swap {
                    amount_in,
                    minimum_amount_out,
                })
            }
            2 => {
                let (pool_token_amount, rest) = Self::unpack_u64(rest)?;
                let (maximum_token_a_amount, rest) = Self::unpack_u64(rest)?;
                let (maximum_token_b_amount, _rest) = Self::unpack_u64(rest)?;
                Self::DepositAllTokenTypes(DepositAllTokenTypes {
                    pool_token_amount,
                    maximum_token_a_amount,
                    maximum_token_b_amount,
                })
            }
            3 => {
                let (pool_token_amount, rest) = Self::unpack_u64(rest)?;
                let (minimum_token_a_amount, rest) = Self::unpack_u64(rest)?;
                let (minimum_token_b_amount, _rest) = Self::unpack_u64(rest)?;
                Self::WithdrawAllTokenTypes(WithdrawAllTokenTypes {
                    pool_token_amount,
                    minimum_token_a_amount,
                    minimum_token_b_amount,
                })
            }
            4 => {
                let (source_token_amount, rest) = Self::unpack_u64(rest)?;
                let (minimum_pool_token_amount, _rest) = Self::unpack_u64(rest)?;
                Self::DepositSingleTokenTypeExactAmountIn(DepositSingleTokenTypeExactAmountIn {
                    source_token_amount,
                    minimum_pool_token_amount,
                })
            }
            5 => {
                let (destination_token_amount, rest) = Self::unpack_u64(rest)?;
                let (maximum_pool_token_amount, _rest) = Self::unpack_u64(rest)?;
                Self::WithdrawSingleTokenTypeExactAmountOut(WithdrawSingleTokenTypeExactAmountOut {
                    destination_token_amount,
                    maximum_pool_token_amount,
                })
            }
            _ => return Err(SwapError::InvalidInstruction.into()),
        })
    }
    fn unpack_u64(input: &[u8]) -> Result<(u64, &[u8]), ProgramError> {
        if input.len() >= 8 {
            let (amount, rest) = input.split_at(8);
            let amount = amount
                .get(..8)
                .and_then(|slice| slice.try_into().ok())
                .map(u64::from_le_bytes)
                .ok_or(SwapError::InvalidInstruction)?;
            Ok((amount, rest))
        } else {
            Err(SwapError::InvalidInstruction.into())
        }
    }
    pub fn pack(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(size_of::<Self>());
        match self {
            Self::Initialize(Initialize { fees, swap_curve }) => {
                buf.push(0);
                let mut fees_slice = [0u8; Fees::LEN];
                Pack::pack_into_slice(fees, &mut fees_slice[..]);
                buf.extend_from_slice(&fees_slice);
                let mut swap_curve_slice = [0u8; SwapCurve::LEN];
                Pack::pack_into_slice(swap_curve, &mut swap_curve_slice[..]);
                buf.extend_from_slice(&swap_curve_slice);
            }
            Self::Swap(Swap {
                amount_in,
                minimum_amount_out,
            }) => {
                buf.push(1);
                buf.extend_from_slice(&amount_in.to_le_bytes());
                buf.extend_from_slice(&minimum_amount_out.to_le_bytes());
            }
            Self::DepositAllTokenTypes(DepositAllTokenTypes {
                pool_token_amount,
                maximum_token_a_amount,
                maximum_token_b_amount,
            }) => {
                buf.push(2);
                buf.extend_from_slice(&pool_token_amount.to_le_bytes());
                buf.extend_from_slice(&maximum_token_a_amount.to_le_bytes());
                buf.extend_from_slice(&maximum_token_b_amount.to_le_bytes());
            }
            Self::WithdrawAllTokenTypes(WithdrawAllTokenTypes {
                pool_token_amount,
                minimum_token_a_amount,
                minimum_token_b_amount,
            }) => {
                buf.push(3);
                buf.extend_from_slice(&pool_token_amount.to_le_bytes());
                buf.extend_from_slice(&minimum_token_a_amount.to_le_bytes());
                buf.extend_from_slice(&minimum_token_b_amount.to_le_bytes());
            }
            Self::DepositSingleTokenTypeExactAmountIn(DepositSingleTokenTypeExactAmountIn {
                source_token_amount,
                minimum_pool_token_amount,
            }) => {
                buf.push(4);
                buf.extend_from_slice(&source_token_amount.to_le_bytes());
                buf.extend_from_slice(&minimum_pool_token_amount.to_le_bytes());
            }
            Self::WithdrawSingleTokenTypeExactAmountOut(
                WithdrawSingleTokenTypeExactAmountOut {
                    destination_token_amount,
                    maximum_pool_token_amount,
                },
            ) => {
                buf.push(5);
                buf.extend_from_slice(&destination_token_amount.to_le_bytes());
                buf.extend_from_slice(&maximum_pool_token_amount.to_le_bytes());
            }
        }
        buf
    }
}
pub fn initialize(
    program_id: &Pubkey,
    token_program_id: &Pubkey,
    swap_pubkey: &Pubkey,
    authority_pubkey: &Pubkey,
    token_a_pubkey: &Pubkey,
    token_b_pubkey: &Pubkey,
    pool_pubkey: &Pubkey,
    fee_pubkey: &Pubkey,
    destination_pubkey: &Pubkey,
    fees: Fees,
    swap_curve: SwapCurve,
) -> Result<Instruction, ProgramError> {
    let init_data = SwapInstruction::Initialize(Initialize { fees, swap_curve });
    let data = init_data.pack();
    let accounts = vec![
        AccountMeta::new(*swap_pubkey, true),
        AccountMeta::new_readonly(*authority_pubkey, false),
        AccountMeta::new_readonly(*token_a_pubkey, false),
        AccountMeta::new_readonly(*token_b_pubkey, false),
        AccountMeta::new(*pool_pubkey, false),
        AccountMeta::new_readonly(*fee_pubkey, false),
        AccountMeta::new(*destination_pubkey, false),
        AccountMeta::new_readonly(*token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn deposit_all_token_types(
    program_id: &Pubkey,
    token_a_program_id: &Pubkey,
    token_b_program_id: &Pubkey,
    pool_token_program_id: &Pubkey,
    swap_pubkey: &Pubkey,
    authority_pubkey: &Pubkey,
    user_transfer_authority_pubkey: &Pubkey,
    deposit_token_a_pubkey: &Pubkey,
    deposit_token_b_pubkey: &Pubkey,
    swap_token_a_pubkey: &Pubkey,
    swap_token_b_pubkey: &Pubkey,
    pool_mint_pubkey: &Pubkey,
    destination_pubkey: &Pubkey,
    token_a_mint_pubkey: &Pubkey,
    token_b_mint_pubkey: &Pubkey,
    instruction: DepositAllTokenTypes,
) -> Result<Instruction, ProgramError> {
    let data = SwapInstruction::DepositAllTokenTypes(instruction).pack();
    let accounts = vec![
        AccountMeta::new_readonly(*swap_pubkey, false),
        AccountMeta::new_readonly(*authority_pubkey, false),
        AccountMeta::new_readonly(*user_transfer_authority_pubkey, true),
        AccountMeta::new(*deposit_token_a_pubkey, false),
        AccountMeta::new(*deposit_token_b_pubkey, false),
        AccountMeta::new(*swap_token_a_pubkey, false),
        AccountMeta::new(*swap_token_b_pubkey, false),
        AccountMeta::new(*pool_mint_pubkey, false),
        AccountMeta::new(*destination_pubkey, false),
        AccountMeta::new_readonly(*token_a_mint_pubkey, false),
        AccountMeta::new_readonly(*token_b_mint_pubkey, false),
        AccountMeta::new_readonly(*token_a_program_id, false),
        AccountMeta::new_readonly(*token_b_program_id, false),
        AccountMeta::new_readonly(*pool_token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn withdraw_all_token_types(
    program_id: &Pubkey,
    pool_token_program_id: &Pubkey,
    token_a_program_id: &Pubkey,
    token_b_program_id: &Pubkey,
    swap_pubkey: &Pubkey,
    authority_pubkey: &Pubkey,
    user_transfer_authority_pubkey: &Pubkey,
    pool_mint_pubkey: &Pubkey,
    fee_account_pubkey: &Pubkey,
    source_pubkey: &Pubkey,
    swap_token_a_pubkey: &Pubkey,
    swap_token_b_pubkey: &Pubkey,
    destination_token_a_pubkey: &Pubkey,
    destination_token_b_pubkey: &Pubkey,
    token_a_mint_pubkey: &Pubkey,
    token_b_mint_pubkey: &Pubkey,
    instruction: WithdrawAllTokenTypes,
) -> Result<Instruction, ProgramError> {
    let data = SwapInstruction::WithdrawAllTokenTypes(instruction).pack();
    let accounts = vec![
        AccountMeta::new_readonly(*swap_pubkey, false),
        AccountMeta::new_readonly(*authority_pubkey, false),
        AccountMeta::new_readonly(*user_transfer_authority_pubkey, true),
        AccountMeta::new(*pool_mint_pubkey, false),
        AccountMeta::new(*source_pubkey, false),
        AccountMeta::new(*swap_token_a_pubkey, false),
        AccountMeta::new(*swap_token_b_pubkey, false),
        AccountMeta::new(*destination_token_a_pubkey, false),
        AccountMeta::new(*destination_token_b_pubkey, false),
        AccountMeta::new(*fee_account_pubkey, false),
        AccountMeta::new_readonly(*token_a_mint_pubkey, false),
        AccountMeta::new_readonly(*token_b_mint_pubkey, false),
        AccountMeta::new_readonly(*pool_token_program_id, false),
        AccountMeta::new_readonly(*token_a_program_id, false),
        AccountMeta::new_readonly(*token_b_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn deposit_single_token_type_exact_amount_in(
    program_id: &Pubkey,
    source_token_program_id: &Pubkey,
    pool_token_program_id: &Pubkey,
    swap_pubkey: &Pubkey,
    authority_pubkey: &Pubkey,
    user_transfer_authority_pubkey: &Pubkey,
    source_token_pubkey: &Pubkey,
    swap_token_a_pubkey: &Pubkey,
    swap_token_b_pubkey: &Pubkey,
    pool_mint_pubkey: &Pubkey,
    destination_pubkey: &Pubkey,
    source_mint_pubkey: &Pubkey,
    instruction: DepositSingleTokenTypeExactAmountIn,
) -> Result<Instruction, ProgramError> {
    let data = SwapInstruction::DepositSingleTokenTypeExactAmountIn(instruction).pack();
    let accounts = vec![
        AccountMeta::new_readonly(*swap_pubkey, false),
        AccountMeta::new_readonly(*authority_pubkey, false),
        AccountMeta::new_readonly(*user_transfer_authority_pubkey, true),
        AccountMeta::new(*source_token_pubkey, false),
        AccountMeta::new(*swap_token_a_pubkey, false),
        AccountMeta::new(*swap_token_b_pubkey, false),
        AccountMeta::new(*pool_mint_pubkey, false),
        AccountMeta::new(*destination_pubkey, false),
        AccountMeta::new_readonly(*source_mint_pubkey, false),
        AccountMeta::new_readonly(*source_token_program_id, false),
        AccountMeta::new_readonly(*pool_token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn withdraw_single_token_type_exact_amount_out(
    program_id: &Pubkey,
    pool_token_program_id: &Pubkey,
    destination_token_program_id: &Pubkey,
    swap_pubkey: &Pubkey,
    authority_pubkey: &Pubkey,
    user_transfer_authority_pubkey: &Pubkey,
    pool_mint_pubkey: &Pubkey,
    fee_account_pubkey: &Pubkey,
    pool_token_source_pubkey: &Pubkey,
    swap_token_a_pubkey: &Pubkey,
    swap_token_b_pubkey: &Pubkey,
    destination_pubkey: &Pubkey,
    destination_mint_pubkey: &Pubkey,
    instruction: WithdrawSingleTokenTypeExactAmountOut,
) -> Result<Instruction, ProgramError> {
    let data = SwapInstruction::WithdrawSingleTokenTypeExactAmountOut(instruction).pack();
    let accounts = vec![
        AccountMeta::new_readonly(*swap_pubkey, false),
        AccountMeta::new_readonly(*authority_pubkey, false),
        AccountMeta::new_readonly(*user_transfer_authority_pubkey, true),
        AccountMeta::new(*pool_mint_pubkey, false),
        AccountMeta::new(*pool_token_source_pubkey, false),
        AccountMeta::new(*swap_token_a_pubkey, false),
        AccountMeta::new(*swap_token_b_pubkey, false),
        AccountMeta::new(*destination_pubkey, false),
        AccountMeta::new(*fee_account_pubkey, false),
        AccountMeta::new_readonly(*destination_mint_pubkey, false),
        AccountMeta::new_readonly(*pool_token_program_id, false),
        AccountMeta::new_readonly(*destination_token_program_id, false),
    ];
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn swap(
    program_id: &Pubkey,
    source_token_program_id: &Pubkey,
    destination_token_program_id: &Pubkey,
    pool_token_program_id: &Pubkey,
    swap_pubkey: &Pubkey,
    authority_pubkey: &Pubkey,
    user_transfer_authority_pubkey: &Pubkey,
    source_pubkey: &Pubkey,
    swap_source_pubkey: &Pubkey,
    swap_destination_pubkey: &Pubkey,
    destination_pubkey: &Pubkey,
    pool_mint_pubkey: &Pubkey,
    pool_fee_pubkey: &Pubkey,
    source_mint_pubkey: &Pubkey,
    destination_mint_pubkey: &Pubkey,
    host_fee_pubkey: Option<&Pubkey>,
    instruction: Swap,
) -> Result<Instruction, ProgramError> {
    let data = SwapInstruction::Swap(instruction).pack();
    let mut accounts = vec![
        AccountMeta::new_readonly(*swap_pubkey, false),
        AccountMeta::new_readonly(*authority_pubkey, false),
        AccountMeta::new_readonly(*user_transfer_authority_pubkey, true),
        AccountMeta::new(*source_pubkey, false),
        AccountMeta::new(*swap_source_pubkey, false),
        AccountMeta::new(*swap_destination_pubkey, false),
        AccountMeta::new(*destination_pubkey, false),
        AccountMeta::new(*pool_mint_pubkey, false),
        AccountMeta::new(*pool_fee_pubkey, false),
        AccountMeta::new_readonly(*source_mint_pubkey, false),
        AccountMeta::new_readonly(*destination_mint_pubkey, false),
        AccountMeta::new_readonly(*source_token_program_id, false),
        AccountMeta::new_readonly(*destination_token_program_id, false),
        AccountMeta::new_readonly(*pool_token_program_id, false),
    ];
    if let Some(host_fee_pubkey) = host_fee_pubkey {
        accounts.push(AccountMeta::new(*host_fee_pubkey, false));
    }
    Ok(Instruction {
        program_id: *program_id,
        accounts,
        data,
    })
}
pub fn unpack<T>(input: &[u8]) -> Result<&T, ProgramError> {
    if input.len() < size_of::<u8>() + size_of::<T>() {
        return Err(ProgramError::InvalidAccountData);
    }
    #[allow(clippy::cast_ptr_alignment)]
    let val: &T = unsafe { &*(&input[1] as *const u8 as *const T) };
    Ok(val)
}