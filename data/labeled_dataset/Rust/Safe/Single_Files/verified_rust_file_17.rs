use {
    crate::{error::GovernanceError, state::enums::GovernanceAccountType},
    borsh::{BorshDeserialize, BorshSchema, BorshSerialize},
    solana_program::{
        account_info::AccountInfo, program_error::ProgramError, program_pack::IsInitialized,
        pubkey::Pubkey,
    },
    spl_governance_tools::account::{get_account_data, AccountMaxSize},
};
#[derive(Clone, Debug, PartialEq, BorshDeserialize, BorshSerialize, BorshSchema)]
pub struct ProposalDeposit {
    pub account_type: GovernanceAccountType,
    pub proposal: Pubkey,
    pub deposit_payer: Pubkey,
    pub reserved: [u8; 64],
}
impl AccountMaxSize for ProposalDeposit {
    fn get_max_size(&self) -> Option<usize> {
        Some(1 + 32 + 32 + 64)
    }
}
impl IsInitialized for ProposalDeposit {
    fn is_initialized(&self) -> bool {
        self.account_type == GovernanceAccountType::ProposalDeposit
    }
}
pub fn get_proposal_deposit_address_seeds<'a>(
    proposal: &'a Pubkey,
    proposal_deposit_payer: &'a Pubkey,
) -> [&'a [u8]; 3] {
    [
        b"proposal-deposit",
        proposal.as_ref(),
        proposal_deposit_payer.as_ref(),
    ]
}
pub fn get_proposal_deposit_address(
    program_id: &Pubkey,
    proposal: &Pubkey,
    proposal_deposit_payer: &Pubkey,
) -> Pubkey {
    Pubkey::find_program_address(
        &get_proposal_deposit_address_seeds(proposal, proposal_deposit_payer),
        program_id,
    )
    .0
}
pub fn get_proposal_deposit_data(
    program_id: &Pubkey,
    proposal_deposit_info: &AccountInfo,
) -> Result<ProposalDeposit, ProgramError> {
    get_account_data::<ProposalDeposit>(program_id, proposal_deposit_info)
}
pub fn get_proposal_deposit_data_for_proposal_and_deposit_payer(
    program_id: &Pubkey,
    proposal_deposit_info: &AccountInfo,
    proposal: &Pubkey,
    proposal_deposit_payer: &Pubkey,
) -> Result<ProposalDeposit, ProgramError> {
    let proposal_deposit_data = get_proposal_deposit_data(program_id, proposal_deposit_info)?;
    if proposal_deposit_data.proposal != *proposal {
        return Err(GovernanceError::InvalidProposalForProposalDeposit.into());
    }
    if proposal_deposit_data.deposit_payer != *proposal_deposit_payer {
        return Err(GovernanceError::InvalidDepositPayerForProposalDeposit.into());
    }
    Ok(proposal_deposit_data)
}