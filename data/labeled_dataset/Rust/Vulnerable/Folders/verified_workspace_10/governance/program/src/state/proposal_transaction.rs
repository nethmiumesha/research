use {
    crate::{
        error::GovernanceError,
        state::{
            enums::{GovernanceAccountType, TransactionExecutionStatus},
            legacy::ProposalInstructionV1,
        },
        PROGRAM_AUTHORITY_SEED,
    },
    borsh::{io::Write, BorshDeserialize, BorshSchema, BorshSerialize},
    core::panic,
    solana_program::{
        account_info::AccountInfo,
        clock::UnixTimestamp,
        instruction::{AccountMeta, Instruction},
        program_error::ProgramError,
        program_pack::IsInitialized,
        pubkey::Pubkey,
    },
    spl_governance_tools::account::{get_account_data, get_account_type, AccountMaxSize},
};
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct InstructionData {
    pub program_id: Pubkey,
    pub accounts: Vec<AccountMetaData>,
    pub data: Vec<u8>,
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct AccountMetaData {
    pub pubkey: Pubkey,
    pub is_signer: bool,
    pub is_writable: bool,
}
impl From<Instruction> for InstructionData {
    fn from(instruction: Instruction) -> Self {
        InstructionData {
            program_id: instruction.program_id,
            accounts: instruction
                .accounts
                .iter()
                .map(|a| AccountMetaData {
                    pubkey: a.pubkey,
                    is_signer: a.is_signer,
                    is_writable: a.is_writable,
                })
                .collect(),
            data: instruction.data,
        }
    }
}
impl From<&InstructionData> for Instruction {
    fn from(instruction: &InstructionData) -> Self {
        Instruction {
            program_id: instruction.program_id,
            accounts: instruction
                .accounts
                .iter()
                .map(|a| AccountMeta {
                    pubkey: a.pubkey,
                    is_signer: a.is_signer,
                    is_writable: a.is_writable,
                })
                .collect(),
            data: instruction.data.clone(),
        }
    }
}
#[derive(Clone, Debug, PartialEq, Eq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProposalTransactionV2 {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub option_index: u8,
    pub transaction_index: u16,
    pub legacy: u32,
    pub instructions: Vec<InstructionData>,
    pub executed_at: Option<UnixTimestamp>,
    pub execution_status: TransactionExecutionStatus,
    pub reserved_v2: [u8; 8],
}
impl AccountMaxSize for ProposalTransactionV2 {
    fn get_max_size(&self) -> Option<usize> {
        let instructions_size = self
            .instructions
            .iter()
            .map(|i| i.accounts.len() * 34 + i.data.len() + 40)
            .sum::<usize>();
        Some(instructions_size + 62)
    }
}
impl IsInitialized for ProposalTransactionV2 {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::ProposalTransactionV2
    }
}
impl ProposalTransactionV2 {
    pub fn serialize<W: Write>(self, writer: W) -> Result<(), ProgramError> {
        if self.account_type == GovernanceAccountType::ProposalTransactionV2 {
            borsh::to_writer(writer, &self)?
        } else if self.account_type == GovernanceAccountType::ProposalInstructionV1 {
            if self.instructions.len() != 1 {
                panic!("Multiple instructions are not supported by ProposalInstructionV1")
            };
            if self.reserved_v2 != [0; 8] {
                panic!("Extended data not supported by ProposalInstructionV1")
            }
            let proposal_transaction_data_v1 = ProposalInstructionV1 {
                account_type: self.account_type,
                proposal: self.proposal,
                instruction_index: self.transaction_index,
                legacy: self.legacy,
                instruction: self.instructions[0].clone(),
                executed_at: self.executed_at,
                execution_status: self.execution_status,
            };
            borsh::to_writer(writer, &proposal_transaction_data_v1)?
        }
        Ok(())
    }
}
pub fn get_proposal_transaction_address_seeds<'a>(
    proposal: &'a Pubkey,
    option_index: &'a [u8; 1],
    instruction_index_le_bytes: &'a [u8; 2],
) -> [&'a [u8]; 4] {
    [
        PROGRAM_AUTHORITY_SEED,
        proposal.as_ref(),
        option_index,
        instruction_index_le_bytes,
    ]
}
pub fn get_proposal_transaction_address<'a>(
    program_id: &Pubkey,
    proposal: &'a Pubkey,
    option_index_le_bytes: &'a [u8; 1],
    instruction_index_le_bytes: &'a [u8; 2],
) -> Pubkey {
    Pubkey::find_program_address(
        &get_proposal_transaction_address_seeds(
            proposal,
            option_index_le_bytes,
            instruction_index_le_bytes,
        ),
        program_id,
    )
    .0
}
pub fn get_proposal_transaction_data(
    program_id: &Pubkey,
    proposal_transaction_info: &AccountInfo,
) -> Result<ProposalTransactionV2, ProgramError> {
    let account_type: GovernanceAccountType =
        get_account_type(program_id, proposal_transaction_info)?;
    if account_type == GovernanceAccountType::ProposalInstructionV1 {
        let proposal_transaction_data_v1 =
            get_account_data::<ProposalInstructionV1>(program_id, proposal_transaction_info)?;
        return Ok(ProposalTransactionV2 {
            account_type,
            proposal: proposal_transaction_data_v1.proposal,
            option_index: 0,
            transaction_index: proposal_transaction_data_v1.instruction_index,
            legacy: proposal_transaction_data_v1.legacy,
            instructions: vec![proposal_transaction_data_v1.instruction],
            executed_at: proposal_transaction_data_v1.executed_at,
            execution_status: proposal_transaction_data_v1.execution_status,
            reserved_v2: [0; 8],
        });
    }
    get_account_data::<ProposalTransactionV2>(program_id, proposal_transaction_info)
}
pub fn get_proposal_transaction_data_for_proposal(
    program_id: &Pubkey,
    proposal_transaction_info: &AccountInfo,
    proposal: &Pubkey,
) -> Result<ProposalTransactionV2, ProgramError> {
    let proposal_transaction_data =
        get_proposal_transaction_data(program_id, proposal_transaction_info)?;
    if proposal_transaction_data.proposal != *proposal {
        return Err(GovernanceError::InvalidProposalForProposalTransaction.into());
    }
    Ok(proposal_transaction_data)
}