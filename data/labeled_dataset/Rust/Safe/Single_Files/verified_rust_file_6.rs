use {
    crate::{
        error::GovernanceError,
        state::{
            enums::ProposalState, governance::get_governance_data_for_realm,
            proposal::get_proposal_data_for_governance, realm::assert_is_valid_realm,
            signatory_record::get_signatory_record_data_for_seeds,
            token_owner_record::get_token_owner_record_data_for_proposal_owner,
        },
    },
    solana_program::{
        account_info::{next_account_info, AccountInfo},
        clock::Clock,
        entrypoint::ProgramResult,
        pubkey::Pubkey,
        sysvar::Sysvar,
    },
};
pub fn process_sign_off_proposal(program_id: &Pubkey, accounts: &[AccountInfo]) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();
    let realm_info = next_account_info(account_info_iter)?;
    let governance_info = next_account_info(account_info_iter)?;
    let proposal_info = next_account_info(account_info_iter)?;
    let signatory_info = next_account_info(account_info_iter)?;
    let clock = Clock::get()?;
    assert_is_valid_realm(program_id, realm_info)?;
    let governance_data =
        get_governance_data_for_realm(program_id, governance_info, realm_info.key)?;
    let mut proposal_data =
        get_proposal_data_for_governance(program_id, proposal_info, governance_info.key)?;
    proposal_data.assert_can_sign_off()?;
    if governance_data.required_signatories_count > 0
        && proposal_data.signatories_count < governance_data.required_signatories_count
    {
        return Err(GovernanceError::MissingRequiredSignatories.into());
    }
    if proposal_data.signatories_count == 0 {
        let proposal_owner_record_info = next_account_info(account_info_iter)?;
        let proposal_owner_record_data = get_token_owner_record_data_for_proposal_owner(
            program_id,
            proposal_owner_record_info,
            &proposal_data.token_owner_record,
        )?;
        proposal_owner_record_data.assert_token_owner_or_delegate_is_signer(signatory_info)?;
        proposal_data.signing_off_at = Some(clock.unix_timestamp);
    } else {
        let signatory_record_info = next_account_info(account_info_iter)?;
        let mut signatory_record_data = get_signatory_record_data_for_seeds(
            program_id,
            signatory_record_info,
            proposal_info.key,
            signatory_info.key,
        )?;
        signatory_record_data.assert_can_sign_off(signatory_info)?;
        signatory_record_data.signed_off = true;
        signatory_record_data.serialize(&mut signatory_record_info.data.borrow_mut()[..])?;
        if proposal_data.signatories_signed_off_count == 0 {
            proposal_data.signing_off_at = Some(clock.unix_timestamp);
            proposal_data.state = ProposalState::SigningOff;
        }
        proposal_data.signatories_signed_off_count = proposal_data
            .signatories_signed_off_count
            .checked_add(1)
            .unwrap();
    }
    if proposal_data.signatories_signed_off_count == proposal_data.signatories_count {
        proposal_data.voting_at = Some(clock.unix_timestamp);
        proposal_data.voting_at_slot = Some(clock.slot);
        proposal_data.state = ProposalState::Voting;
    }
    proposal_data.serialize(&mut proposal_info.data.borrow_mut()[..])?;
    Ok(())
}