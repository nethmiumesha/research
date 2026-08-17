use {
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        clock::Slot,
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
        system_program,
    },
    spl_governance_addin_api::voter_weight::VoterWeightAction,
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
#[allow(clippy::large_enum_variant)]
pub enum VoterWeightAddinInstruction {
    SetupVoterWeightRecord {
        #[allow(dead_code)]
        voter_weight: u64,
        #[allow(dead_code)]
        voter_weight_expiry: Option<Slot>,
        #[allow(dead_code)]
        weight_action: Option<VoterWeightAction>,
        #[allow(dead_code)]
        weight_action_target: Option<Pubkey>,
    },
    SetupMaxVoterWeightRecord {
        #[allow(dead_code)]
        max_voter_weight: u64,
        #[allow(dead_code)]
        max_voter_weight_expiry: Option<Slot>,
    },
}
#[allow(clippy::too_many_arguments)]
pub fn setup_voter_weight_record(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_mint: &Pubkey,
    governing_token_owner: &Pubkey,
    voter_weight_record: &Pubkey,
    payer: &Pubkey,
    voter_weight: u64,
    voter_weight_expiry: Option<Slot>,
    weight_action: Option<VoterWeightAction>,
    weight_action_target: Option<Pubkey>,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(*governing_token_mint, false),
        AccountMeta::new_readonly(*governing_token_owner, false),
        AccountMeta::new(*voter_weight_record, true),
        AccountMeta::new_readonly(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = VoterWeightAddinInstruction::SetupVoterWeightRecord {
        voter_weight,
        voter_weight_expiry,
        weight_action,
        weight_action_target,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn setup_max_voter_weight_record(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_mint: &Pubkey,
    max_voter_weight_record: &Pubkey,
    payer: &Pubkey,
    max_voter_weight: u64,
    max_voter_weight_expiry: Option<Slot>,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(*governing_token_mint, false),
        AccountMeta::new(*max_voter_weight_record, true),
        AccountMeta::new_readonly(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = VoterWeightAddinInstruction::SetupMaxVoterWeightRecord {
        max_voter_weight,
        max_voter_weight_expiry,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}