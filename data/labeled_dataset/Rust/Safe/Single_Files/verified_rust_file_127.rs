use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
        system_program,
    },
};
#[repr(C)]
#[derive(Clone, Debug, PartialEq, BorshSerialize, BorshDeserialize, BorshSchema)]
pub enum StatelessOfferInstruction {
    AcceptOffer {
        #[allow(dead_code)]
        has_metadata: bool,
        #[allow(dead_code)]
        maker_size: u64,
        #[allow(dead_code)]
        taker_size: u64,
        #[allow(dead_code)]
        bump_seed: u8,
    },
}
#[allow(clippy::too_many_arguments)]
pub fn accept_offer(
    program_id: &Pubkey,
    maker_wallet: &Pubkey,
    taker_wallet: &Pubkey,
    maker_src_account: &Pubkey,
    maker_dst_account: &Pubkey,
    taker_src_account: &Pubkey,
    taker_dst_account: &Pubkey,
    maker_mint: &Pubkey,
    taker_mint: &Pubkey,
    authority: &Pubkey,
    token_program_id: &Pubkey,
    is_native: bool,
    maker_size: u64,
    taker_size: u64,
    bump_seed: u8,
) -> Instruction {
    let init_data = StatelessOfferInstruction::AcceptOffer {
        has_metadata: false,
        maker_size,
        taker_size,
        bump_seed,
    };
    let data = borsh::to_vec(&init_data).unwrap();
    let mut accounts = vec![
        AccountMeta::new_readonly(*maker_wallet, false),
        AccountMeta::new_readonly(*taker_wallet, true),
        AccountMeta::new(*maker_src_account, false),
        AccountMeta::new(*maker_dst_account, false),
        AccountMeta::new(*taker_src_account, false),
        AccountMeta::new(*taker_dst_account, false),
        AccountMeta::new_readonly(*maker_mint, false),
        AccountMeta::new_readonly(*taker_mint, false),
        AccountMeta::new_readonly(*authority, false),
        AccountMeta::new_readonly(*token_program_id, false),
    ];
    if is_native {
        accounts.push(AccountMeta::new_readonly(system_program::id(), false));
    }
    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}
#[allow(clippy::too_many_arguments)]
pub fn accept_offer_with_metadata(
    program_id: &Pubkey,
    maker_wallet: &Pubkey,
    taker_wallet: &Pubkey,
    maker_src_account: &Pubkey,
    maker_dst_account: &Pubkey,
    taker_src_account: &Pubkey,
    taker_dst_account: &Pubkey,
    maker_mint: &Pubkey,
    taker_mint: &Pubkey,
    authority: &Pubkey,
    token_program_id: &Pubkey,
    metadata: &Pubkey,
    creators: &[&Pubkey],
    is_native: bool,
    maker_size: u64,
    taker_size: u64,
    bump_seed: u8,
) -> Instruction {
    let init_data = StatelessOfferInstruction::AcceptOffer {
        has_metadata: true,
        maker_size,
        taker_size,
        bump_seed,
    };
    let data = borsh::to_vec(&init_data).unwrap();
    let mut accounts = vec![
        AccountMeta::new_readonly(*maker_wallet, false),
        AccountMeta::new_readonly(*taker_wallet, true),
        AccountMeta::new(*maker_src_account, false),
        AccountMeta::new(*maker_dst_account, false),
        AccountMeta::new(*taker_src_account, false),
        AccountMeta::new(*taker_dst_account, false),
        AccountMeta::new_readonly(*maker_mint, false),
        AccountMeta::new_readonly(*taker_mint, false),
        AccountMeta::new_readonly(*authority, false),
        AccountMeta::new_readonly(*token_program_id, false),
    ];
    if is_native {
        accounts.push(AccountMeta::new_readonly(system_program::id(), false));
    }
    accounts.push(AccountMeta::new_readonly(*metadata, false));
    for creator in creators.iter() {
        accounts.push(AccountMeta::new(**creator, false));
    }
    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}