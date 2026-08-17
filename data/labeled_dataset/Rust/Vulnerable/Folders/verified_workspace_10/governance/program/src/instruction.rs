use {
    crate::state::{
        enums::MintMaxVoterWeightSource,
        governance::{get_governance_address, GovernanceConfig},
        native_treasury::get_native_treasury_address,
        program_metadata::get_program_metadata_address,
        proposal::{get_proposal_address, VoteType},
        proposal_deposit::get_proposal_deposit_address,
        proposal_transaction::{get_proposal_transaction_address, InstructionData},
        realm::{
            get_governing_token_holding_address, get_realm_address,
            GoverningTokenConfigAccountArgs, GoverningTokenConfigArgs, RealmConfigArgs,
            SetRealmAuthorityAction, SetRealmConfigItemArgs,
        },
        realm_config::get_realm_config_address,
        required_signatory::get_required_signatory_address,
        signatory_record::get_signatory_record_address,
        token_owner_record::get_token_owner_record_address,
        vote_record::{get_vote_record_address, Vote},
    },
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        clock::UnixTimestamp,
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
        system_program, sysvar,
    },
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
#[allow(clippy::large_enum_variant)]
pub enum GovernanceInstruction {
    CreateRealm {
        #[allow(dead_code)]
        name: String,
        #[allow(dead_code)]
        config_args: RealmConfigArgs,
    },
    DepositGoverningTokens {
        #[allow(dead_code)]
        amount: u64,
    },
    WithdrawGoverningTokens {},
    SetGovernanceDelegate {
        #[allow(dead_code)]
        new_governance_delegate: Option<Pubkey>,
    },
    CreateGovernance {
        #[allow(dead_code)]
        config: GovernanceConfig,
    },
    Legacy4,
    CreateProposal {
        #[allow(dead_code)]
        name: String,
        #[allow(dead_code)]
        description_link: String,
        #[allow(dead_code)]
        vote_type: VoteType,
        #[allow(dead_code)]
        options: Vec<String>,
        #[allow(dead_code)]
        use_deny_option: bool,
        #[allow(dead_code)]
        proposal_seed: Pubkey,
    },
    AddSignatory {
        #[allow(dead_code)]
        signatory: Pubkey,
    },
    Legacy1,
    InsertTransaction {
        #[allow(dead_code)]
        option_index: u8,
        #[allow(dead_code)]
        index: u16,
        #[allow(dead_code)]
        legacy: u32,
        #[allow(dead_code)]
        instructions: Vec<InstructionData>,
    },
    RemoveTransaction,
    CancelProposal,
    SignOffProposal,
    CastVote {
        #[allow(dead_code)]
        vote: Vote,
    },
    FinalizeVote {},
    RelinquishVote,
    ExecuteTransaction,
    Legacy2,
    Legacy3,
    SetGovernanceConfig {
        #[allow(dead_code)]
        config: GovernanceConfig,
    },
    Legacy5,
    SetRealmAuthority {
        #[allow(dead_code)]
        action: SetRealmAuthorityAction,
    },
    SetRealmConfig {
        #[allow(dead_code)]
        config_args: RealmConfigArgs,
    },
    CreateTokenOwnerRecord {},
    UpdateProgramMetadata {},
    CreateNativeTreasury,
    RevokeGoverningTokens {
        #[allow(dead_code)]
        amount: u64,
    },
    RefundProposalDeposit {},
    CompleteProposal {},
    AddRequiredSignatory {
        #[allow(dead_code)]
        signatory: Pubkey,
    },
    RemoveRequiredSignatory,
    SetTokenOwnerRecordLock {
        #[allow(dead_code)]
        lock_id: u8,
        #[allow(dead_code)]
        expiry: Option<UnixTimestamp>,
    },
    RelinquishTokenOwnerRecordLocks {
        #[allow(dead_code)]
        lock_ids: Option<Vec<u8>>,
    },
    SetRealmConfigItem {
        #[allow(dead_code)]
        args: SetRealmConfigItemArgs,
    },
}
#[allow(clippy::too_many_arguments)]
pub fn create_realm(
    program_id: &Pubkey,
    realm_authority: &Pubkey,
    community_token_mint: &Pubkey,
    payer: &Pubkey,
    council_token_mint: Option<Pubkey>,
    community_token_config_args: Option<GoverningTokenConfigAccountArgs>,
    council_token_config_args: Option<GoverningTokenConfigAccountArgs>,
    name: String,
    min_community_weight_to_create_governance: u64,
    community_mint_max_voter_weight_source: MintMaxVoterWeightSource,
) -> Instruction {
    let realm_address = get_realm_address(program_id, &name);
    let community_token_holding_address =
        get_governing_token_holding_address(program_id, &realm_address, community_token_mint);
    let mut accounts = vec![
        AccountMeta::new(realm_address, false),
        AccountMeta::new_readonly(*realm_authority, false),
        AccountMeta::new_readonly(*community_token_mint, false),
        AccountMeta::new(community_token_holding_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
        AccountMeta::new_readonly(spl_token::id(), false),
        AccountMeta::new_readonly(sysvar::rent::id(), false),
    ];
    let use_council_mint = if let Some(council_token_mint) = council_token_mint {
        let council_token_holding_address =
            get_governing_token_holding_address(program_id, &realm_address, &council_token_mint);
        accounts.push(AccountMeta::new_readonly(council_token_mint, false));
        accounts.push(AccountMeta::new(council_token_holding_address, false));
        true
    } else {
        false
    };
    let realm_config_address = get_realm_config_address(program_id, &realm_address);
    accounts.push(AccountMeta::new(realm_config_address, false));
    let community_token_config_args =
        with_governing_token_config_args(&mut accounts, community_token_config_args);
    let council_token_config_args =
        with_governing_token_config_args(&mut accounts, council_token_config_args);
    let instruction = GovernanceInstruction::CreateRealm {
        config_args: RealmConfigArgs {
            use_council_mint,
            min_community_weight_to_create_governance,
            community_mint_max_voter_weight_source,
            community_token_config_args,
            council_token_config_args,
        },
        name,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn deposit_governing_tokens(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_source: &Pubkey,
    governing_token_owner: &Pubkey,
    governing_token_source_authority: &Pubkey,
    payer: &Pubkey,
    amount: u64,
    governing_token_mint: &Pubkey,
) -> Instruction {
    let token_owner_record_address = get_token_owner_record_address(
        program_id,
        realm,
        governing_token_mint,
        governing_token_owner,
    );
    let governing_token_holding_address =
        get_governing_token_holding_address(program_id, realm, governing_token_mint);
    let realm_config_address = get_realm_config_address(program_id, realm);
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(governing_token_holding_address, false),
        AccountMeta::new(*governing_token_source, false),
        AccountMeta::new_readonly(*governing_token_owner, true),
        AccountMeta::new_readonly(*governing_token_source_authority, true),
        AccountMeta::new(token_owner_record_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
        AccountMeta::new_readonly(spl_token::id(), false),
        AccountMeta::new_readonly(realm_config_address, false),
    ];
    let instruction = GovernanceInstruction::DepositGoverningTokens { amount };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn withdraw_governing_tokens(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_destination: &Pubkey,
    governing_token_owner: &Pubkey,
    governing_token_mint: &Pubkey,
) -> Instruction {
    let token_owner_record_address = get_token_owner_record_address(
        program_id,
        realm,
        governing_token_mint,
        governing_token_owner,
    );
    let governing_token_holding_address =
        get_governing_token_holding_address(program_id, realm, governing_token_mint);
    let realm_config_address = get_realm_config_address(program_id, realm);
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(governing_token_holding_address, false),
        AccountMeta::new(*governing_token_destination, false),
        AccountMeta::new_readonly(*governing_token_owner, true),
        AccountMeta::new(token_owner_record_address, false),
        AccountMeta::new_readonly(spl_token::id(), false),
        AccountMeta::new_readonly(realm_config_address, false),
    ];
    let instruction = GovernanceInstruction::WithdrawGoverningTokens {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn set_governance_delegate(
    program_id: &Pubkey,
    governance_authority: &Pubkey,
    realm: &Pubkey,
    governing_token_mint: &Pubkey,
    governing_token_owner: &Pubkey,
    new_governance_delegate: &Option<Pubkey>,
) -> Instruction {
    let vote_record_address = get_token_owner_record_address(
        program_id,
        realm,
        governing_token_mint,
        governing_token_owner,
    );
    let accounts = vec![
        AccountMeta::new_readonly(*governance_authority, true),
        AccountMeta::new(vote_record_address, false),
    ];
    let instruction = GovernanceInstruction::SetGovernanceDelegate {
        new_governance_delegate: *new_governance_delegate,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn create_governance(
    program_id: &Pubkey,
    realm: &Pubkey,
    governance_seed: &Pubkey,
    token_owner_record: &Pubkey,
    payer: &Pubkey,
    create_authority: &Pubkey,
    voter_weight_record: Option<Pubkey>,
    config: GovernanceConfig,
) -> Instruction {
    let governance_address = get_governance_address(program_id, realm, governance_seed);
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(governance_address, false),
        AccountMeta::new_readonly(*governance_seed, false),
        AccountMeta::new_readonly(*token_owner_record, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
        AccountMeta::new_readonly(*create_authority, true),
    ];
    with_realm_config_accounts(program_id, &mut accounts, realm, voter_weight_record, None);
    let instruction = GovernanceInstruction::CreateGovernance { config };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn create_proposal(
    program_id: &Pubkey,
    governance: &Pubkey,
    proposal_owner_record: &Pubkey,
    governance_authority: &Pubkey,
    payer: &Pubkey,
    voter_weight_record: Option<Pubkey>,
    realm: &Pubkey,
    name: String,
    description_link: String,
    governing_token_mint: &Pubkey,
    vote_type: VoteType,
    options: Vec<String>,
    use_deny_option: bool,
    proposal_seed: &Pubkey,
) -> Instruction {
    let proposal_address =
        get_proposal_address(program_id, governance, governing_token_mint, proposal_seed);
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(proposal_address, false),
        AccountMeta::new(*governance, false),
        AccountMeta::new(*proposal_owner_record, false),
        AccountMeta::new_readonly(*governing_token_mint, false),
        AccountMeta::new_readonly(*governance_authority, true),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    with_realm_config_accounts(program_id, &mut accounts, realm, voter_weight_record, None);
    let proposal_deposit_address =
        get_proposal_deposit_address(program_id, &proposal_address, payer);
    accounts.push(AccountMeta::new(proposal_deposit_address, false));
    let instruction = GovernanceInstruction::CreateProposal {
        name,
        description_link,
        vote_type,
        options,
        use_deny_option,
        proposal_seed: *proposal_seed,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn add_signatory(
    program_id: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    add_signatory_authority: &AddSignatoryAuthority,
    payer: &Pubkey,
    signatory: &Pubkey,
) -> Instruction {
    let signatory_record_address = get_signatory_record_address(program_id, proposal, signatory);
    let mut accounts = vec![
        AccountMeta::new_readonly(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new(signatory_record_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    match add_signatory_authority {
        AddSignatoryAuthority::ProposalOwner {
            governance_authority,
            token_owner_record,
        } => {
            accounts.push(AccountMeta::new_readonly(*token_owner_record, false));
            accounts.push(AccountMeta::new_readonly(*governance_authority, true));
        }
        AddSignatoryAuthority::None => {
            accounts.push(AccountMeta::new_readonly(
                get_required_signatory_address(program_id, governance, signatory),
                false,
            ));
        }
    };
    let instruction = GovernanceInstruction::AddSignatory {
        signatory: *signatory,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[derive(Debug, Copy, Clone)]
pub enum AddSignatoryAuthority {
    ProposalOwner {
        governance_authority: Pubkey,
        token_owner_record: Pubkey,
    },
    None,
}
pub fn sign_off_proposal(
    program_id: &Pubkey,
    realm: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    signatory: &Pubkey,
    proposal_owner_record: Option<&Pubkey>,
) -> Instruction {
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new_readonly(*signatory, true),
    ];
    if let Some(proposal_owner_record) = proposal_owner_record {
        accounts.push(AccountMeta::new_readonly(*proposal_owner_record, false))
    } else {
        let signatory_record_address =
            get_signatory_record_address(program_id, proposal, signatory);
        accounts.push(AccountMeta::new(signatory_record_address, false));
    }
    let instruction = GovernanceInstruction::SignOffProposal;
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn cast_vote(
    program_id: &Pubkey,
    realm: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    proposal_owner_record: &Pubkey,
    voter_token_owner_record: &Pubkey,
    governance_authority: &Pubkey,
    vote_governing_token_mint: &Pubkey,
    payer: &Pubkey,
    voter_weight_record: Option<Pubkey>,
    max_voter_weight_record: Option<Pubkey>,
    vote: Vote,
) -> Instruction {
    let vote_record_address =
        get_vote_record_address(program_id, proposal, voter_token_owner_record);
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new(*proposal_owner_record, false),
        AccountMeta::new(*voter_token_owner_record, false),
        AccountMeta::new_readonly(*governance_authority, true),
        AccountMeta::new(vote_record_address, false),
        AccountMeta::new_readonly(*vote_governing_token_mint, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    with_realm_config_accounts(
        program_id,
        &mut accounts,
        realm,
        voter_weight_record,
        max_voter_weight_record,
    );
    let instruction = GovernanceInstruction::CastVote { vote };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn finalize_vote(
    program_id: &Pubkey,
    realm: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    proposal_owner_record: &Pubkey,
    governing_token_mint: &Pubkey,
    max_voter_weight_record: Option<Pubkey>,
) -> Instruction {
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new(*proposal_owner_record, false),
        AccountMeta::new_readonly(*governing_token_mint, false),
    ];
    with_realm_config_accounts(
        program_id,
        &mut accounts,
        realm,
        None,
        max_voter_weight_record,
    );
    let instruction = GovernanceInstruction::FinalizeVote {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn relinquish_vote(
    program_id: &Pubkey,
    realm: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    token_owner_record: &Pubkey,
    vote_governing_token_mint: &Pubkey,
    governance_authority: Option<Pubkey>,
    beneficiary: Option<Pubkey>,
) -> Instruction {
    let vote_record_address = get_vote_record_address(program_id, proposal, token_owner_record);
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new(*token_owner_record, false),
        AccountMeta::new(vote_record_address, false),
        AccountMeta::new_readonly(*vote_governing_token_mint, false),
    ];
    if let Some(governance_authority) = governance_authority {
        accounts.push(AccountMeta::new_readonly(governance_authority, true));
        accounts.push(AccountMeta::new(beneficiary.unwrap(), false));
    }
    let instruction = GovernanceInstruction::RelinquishVote {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn cancel_proposal(
    program_id: &Pubkey,
    realm: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    proposal_owner_record: &Pubkey,
    governance_authority: &Pubkey,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new(*proposal_owner_record, false),
        AccountMeta::new_readonly(*governance_authority, true),
    ];
    let instruction = GovernanceInstruction::CancelProposal {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn insert_transaction(
    program_id: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    token_owner_record: &Pubkey,
    governance_authority: &Pubkey,
    payer: &Pubkey,
    option_index: u8,
    index: u16,
    instructions: Vec<InstructionData>,
) -> Instruction {
    let proposal_transaction_address = get_proposal_transaction_address(
        program_id,
        proposal,
        &option_index.to_le_bytes(),
        &index.to_le_bytes(),
    );
    let accounts = vec![
        AccountMeta::new_readonly(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new_readonly(*token_owner_record, false),
        AccountMeta::new_readonly(*governance_authority, true),
        AccountMeta::new(proposal_transaction_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
        AccountMeta::new_readonly(sysvar::rent::id(), false),
    ];
    let instruction = GovernanceInstruction::InsertTransaction {
        option_index,
        index,
        legacy: 0,
        instructions,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn remove_transaction(
    program_id: &Pubkey,
    proposal: &Pubkey,
    token_owner_record: &Pubkey,
    governance_authority: &Pubkey,
    proposal_transaction: &Pubkey,
    beneficiary: &Pubkey,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new(*proposal, false),
        AccountMeta::new_readonly(*token_owner_record, false),
        AccountMeta::new_readonly(*governance_authority, true),
        AccountMeta::new(*proposal_transaction, false),
        AccountMeta::new(*beneficiary, false),
    ];
    let instruction = GovernanceInstruction::RemoveTransaction {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn execute_transaction(
    program_id: &Pubkey,
    governance: &Pubkey,
    proposal: &Pubkey,
    proposal_transaction: &Pubkey,
    instruction_program_id: &Pubkey,
    instruction_accounts: &[AccountMeta],
) -> Instruction {
    let mut accounts = vec![
        AccountMeta::new_readonly(*governance, false),
        AccountMeta::new(*proposal, false),
        AccountMeta::new(*proposal_transaction, false),
        AccountMeta::new_readonly(*instruction_program_id, false),
    ];
    accounts.extend_from_slice(instruction_accounts);
    let instruction = GovernanceInstruction::ExecuteTransaction {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn set_governance_config(
    program_id: &Pubkey,
    governance: &Pubkey,
    config: GovernanceConfig,
) -> Instruction {
    let accounts = vec![AccountMeta::new(*governance, true)];
    let instruction = GovernanceInstruction::SetGovernanceConfig { config };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn set_realm_authority(
    program_id: &Pubkey,
    realm: &Pubkey,
    realm_authority: &Pubkey,
    new_realm_authority: Option<&Pubkey>,
    action: SetRealmAuthorityAction,
) -> Instruction {
    let mut accounts = vec![
        AccountMeta::new(*realm, false),
        AccountMeta::new_readonly(*realm_authority, true),
    ];
    match action {
        SetRealmAuthorityAction::SetChecked | SetRealmAuthorityAction::SetUnchecked => {
            accounts.push(AccountMeta::new_readonly(
                *new_realm_authority.unwrap(),
                false,
            ));
        }
        SetRealmAuthorityAction::Remove => {}
    }
    let instruction = GovernanceInstruction::SetRealmAuthority { action };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn set_realm_config(
    program_id: &Pubkey,
    realm: &Pubkey,
    realm_authority: &Pubkey,
    council_token_mint: Option<Pubkey>,
    payer: &Pubkey,
    community_token_config_args: Option<GoverningTokenConfigAccountArgs>,
    council_token_config_args: Option<GoverningTokenConfigAccountArgs>,
    min_community_weight_to_create_governance: u64,
    community_mint_max_voter_weight_source: MintMaxVoterWeightSource,
) -> Instruction {
    let mut accounts = vec![
        AccountMeta::new(*realm, false),
        AccountMeta::new_readonly(*realm_authority, true),
    ];
    let use_council_mint = if let Some(council_token_mint) = council_token_mint {
        let council_token_holding_address =
            get_governing_token_holding_address(program_id, realm, &council_token_mint);
        accounts.push(AccountMeta::new_readonly(council_token_mint, false));
        accounts.push(AccountMeta::new(council_token_holding_address, false));
        true
    } else {
        false
    };
    accounts.push(AccountMeta::new_readonly(system_program::id(), false));
    let realm_config_address = get_realm_config_address(program_id, realm);
    accounts.push(AccountMeta::new(realm_config_address, false));
    let community_token_config_args =
        with_governing_token_config_args(&mut accounts, community_token_config_args);
    let council_token_config_args =
        with_governing_token_config_args(&mut accounts, council_token_config_args);
    accounts.push(AccountMeta::new(*payer, true));
    let instruction = GovernanceInstruction::SetRealmConfig {
        config_args: RealmConfigArgs {
            use_council_mint,
            min_community_weight_to_create_governance,
            community_mint_max_voter_weight_source,
            community_token_config_args,
            council_token_config_args,
        },
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn with_realm_config_accounts(
    program_id: &Pubkey,
    accounts: &mut Vec<AccountMeta>,
    realm: &Pubkey,
    voter_weight_record: Option<Pubkey>,
    max_voter_weight_record: Option<Pubkey>,
) {
    let realm_config_address = get_realm_config_address(program_id, realm);
    accounts.push(AccountMeta::new_readonly(realm_config_address, false));
    if let Some(voter_weight_record) = voter_weight_record {
        accounts.push(AccountMeta::new_readonly(voter_weight_record, false));
        true
    } else {
        false
    };
    if let Some(max_voter_weight_record) = max_voter_weight_record {
        accounts.push(AccountMeta::new_readonly(max_voter_weight_record, false));
        true
    } else {
        false
    };
}
pub fn create_token_owner_record(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_owner: &Pubkey,
    governing_token_mint: &Pubkey,
    payer: &Pubkey,
) -> Instruction {
    let token_owner_record_address = get_token_owner_record_address(
        program_id,
        realm,
        governing_token_mint,
        governing_token_owner,
    );
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(*governing_token_owner, false),
        AccountMeta::new(token_owner_record_address, false),
        AccountMeta::new_readonly(*governing_token_mint, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = GovernanceInstruction::CreateTokenOwnerRecord {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn upgrade_program_metadata(
    program_id: &Pubkey,
    payer: &Pubkey,
) -> Instruction {
    let program_metadata_address = get_program_metadata_address(program_id);
    let accounts = vec![
        AccountMeta::new(program_metadata_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = GovernanceInstruction::UpdateProgramMetadata {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn create_native_treasury(
    program_id: &Pubkey,
    governance: &Pubkey,
    payer: &Pubkey,
) -> Instruction {
    let native_treasury_address = get_native_treasury_address(program_id, governance);
    let accounts = vec![
        AccountMeta::new_readonly(*governance, false),
        AccountMeta::new(native_treasury_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = GovernanceInstruction::CreateNativeTreasury {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
#[allow(clippy::too_many_arguments)]
pub fn revoke_governing_tokens(
    program_id: &Pubkey,
    realm: &Pubkey,
    governing_token_owner: &Pubkey,
    governing_token_mint: &Pubkey,
    revoke_authority: &Pubkey,
    amount: u64,
) -> Instruction {
    let token_owner_record_address = get_token_owner_record_address(
        program_id,
        realm,
        governing_token_mint,
        governing_token_owner,
    );
    let governing_token_holding_address =
        get_governing_token_holding_address(program_id, realm, governing_token_mint);
    let realm_config_address = get_realm_config_address(program_id, realm);
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new(governing_token_holding_address, false),
        AccountMeta::new(token_owner_record_address, false),
        AccountMeta::new(*governing_token_mint, false),
        AccountMeta::new_readonly(*revoke_authority, true),
        AccountMeta::new_readonly(realm_config_address, false),
        AccountMeta::new_readonly(spl_token::id(), false),
    ];
    let instruction = GovernanceInstruction::RevokeGoverningTokens { amount };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn add_required_signatory(
    program_id: &Pubkey,
    governance: &Pubkey,
    payer: &Pubkey,
    signatory: &Pubkey,
) -> Instruction {
    let required_signatory_address =
        get_required_signatory_address(program_id, governance, signatory);
    let accounts = vec![
        AccountMeta::new(*governance, true),
        AccountMeta::new(required_signatory_address, false),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = GovernanceInstruction::AddRequiredSignatory {
        signatory: *signatory,
    };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn remove_required_signatory(
    program_id: &Pubkey,
    governance: &Pubkey,
    signatory: &Pubkey,
    beneficiary: &Pubkey,
) -> Instruction {
    let required_signatory_address =
        get_required_signatory_address(program_id, governance, signatory);
    let accounts = vec![
        AccountMeta::new(*governance, true),
        AccountMeta::new(required_signatory_address, false),
        AccountMeta::new(*beneficiary, false),
    ];
    let instruction = GovernanceInstruction::RemoveRequiredSignatory;
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn with_governing_token_config_args(
    accounts: &mut Vec<AccountMeta>,
    governing_token_config_args: Option<GoverningTokenConfigAccountArgs>,
) -> GoverningTokenConfigArgs {
    let governing_token_config_args = governing_token_config_args.unwrap_or_default();
    let use_voter_weight_addin =
        if let Some(voter_weight_addin) = governing_token_config_args.voter_weight_addin {
            accounts.push(AccountMeta::new_readonly(voter_weight_addin, false));
            true
        } else {
            false
        };
    let use_max_voter_weight_addin =
        if let Some(max_voter_weight_addin) = governing_token_config_args.max_voter_weight_addin {
            accounts.push(AccountMeta::new_readonly(max_voter_weight_addin, false));
            true
        } else {
            false
        };
    GoverningTokenConfigArgs {
        use_voter_weight_addin,
        use_max_voter_weight_addin,
        token_type: governing_token_config_args.token_type,
    }
}
#[allow(clippy::too_many_arguments)]
pub fn refund_proposal_deposit(
    program_id: &Pubkey,
    proposal: &Pubkey,
    proposal_deposit_payer: &Pubkey,
) -> Instruction {
    let proposal_deposit_address =
        get_proposal_deposit_address(program_id, proposal, proposal_deposit_payer);
    let accounts = vec![
        AccountMeta::new_readonly(*proposal, false),
        AccountMeta::new(proposal_deposit_address, false),
        AccountMeta::new(*proposal_deposit_payer, false),
    ];
    let instruction = GovernanceInstruction::RefundProposalDeposit {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn complete_proposal(
    program_id: &Pubkey,
    proposal: &Pubkey,
    token_owner_record: &Pubkey,
    complete_proposal_authority: &Pubkey,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new(*proposal, false),
        AccountMeta::new_readonly(*token_owner_record, false),
        AccountMeta::new_readonly(*complete_proposal_authority, true),
    ];
    let instruction = GovernanceInstruction::CompleteProposal {};
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn set_token_owner_record_lock(
    program_id: &Pubkey,
    realm: &Pubkey,
    token_owner_record: &Pubkey,
    token_owner_record_lock_authority: &Pubkey,
    payer: &Pubkey,
    lock_id: u8,
    expiry: Option<UnixTimestamp>,
) -> Instruction {
    let realm_config_address = get_realm_config_address(program_id, realm);
    let accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(realm_config_address, false),
        AccountMeta::new(*token_owner_record, false),
        AccountMeta::new_readonly(*token_owner_record_lock_authority, true),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = GovernanceInstruction::SetTokenOwnerRecordLock { lock_id, expiry };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn relinquish_token_owner_record_locks(
    program_id: &Pubkey,
    realm: &Pubkey,
    token_owner_record: &Pubkey,
    token_owner_record_lock_authority: Option<Pubkey>,
    lock_ids: Option<Vec<u8>>,
) -> Instruction {
    let realm_config_address = get_realm_config_address(program_id, realm);
    let mut accounts = vec![
        AccountMeta::new_readonly(*realm, false),
        AccountMeta::new_readonly(realm_config_address, false),
        AccountMeta::new(*token_owner_record, false),
    ];
    if let Some(token_owner_record_lock_authority) = token_owner_record_lock_authority {
        accounts.push(AccountMeta::new_readonly(
            token_owner_record_lock_authority,
            true,
        ));
    }
    let instruction = GovernanceInstruction::RelinquishTokenOwnerRecordLocks { lock_ids };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}
pub fn set_realm_config_item(
    program_id: &Pubkey,
    realm: &Pubkey,
    realm_authority: &Pubkey,
    payer: &Pubkey,
    args: SetRealmConfigItemArgs,
) -> Instruction {
    let realm_config_address = get_realm_config_address(program_id, realm);
    let accounts = vec![
        AccountMeta::new(*realm, false),
        AccountMeta::new(realm_config_address, false),
        AccountMeta::new_readonly(*realm_authority, true),
        AccountMeta::new(*payer, true),
        AccountMeta::new_readonly(system_program::id(), false),
    ];
    let instruction = GovernanceInstruction::SetRealmConfigItem { args };
    Instruction {
        program_id: *program_id,
        accounts,
        data: borsh::to_vec(&instruction).unwrap(),
    }
}