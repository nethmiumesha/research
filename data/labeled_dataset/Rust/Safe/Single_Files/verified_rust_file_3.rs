use {
    crate::{
        error::GovernanceError,
        state::{
            realm::{
                assert_valid_realm_config_args, get_realm_data_for_authority, RealmConfigArgs,
            },
            realm_config::{get_realm_config_data_for_realm, resolve_governing_token_config},
        },
    },
    solana_program::{
        account_info::{next_account_info, AccountInfo},
        entrypoint::ProgramResult,
        pubkey::Pubkey,
        rent::Rent,
        sysvar::Sysvar,
    },
};
pub fn process_set_realm_config(
    program_id: &Pubkey,
    accounts: &[AccountInfo],
    realm_config_args: RealmConfigArgs,
) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();
    let realm_info = next_account_info(account_info_iter)?;
    let realm_authority_info = next_account_info(account_info_iter)?;
    let mut realm_data =
        get_realm_data_for_authority(program_id, realm_info, realm_authority_info.key)?;
    if !realm_authority_info.is_signer {
        return Err(GovernanceError::RealmAuthorityMustSign.into());
    }
    assert_valid_realm_config_args(&realm_config_args)?;
    if realm_config_args.use_council_mint {
        let council_token_mint_info = next_account_info(account_info_iter)?;
        let _council_token_holding_info = next_account_info(account_info_iter)?;
        if let Some(council_token_mint) = realm_data.config.council_mint {
            if council_token_mint != *council_token_mint_info.key {
                return Err(GovernanceError::RealmCouncilMintChangeIsNotSupported.into());
            }
        } else {
            return Err(GovernanceError::RealmCouncilMintChangeIsNotSupported.into());
        }
    } else {
        realm_data.config.council_mint = None;
    }
    let system_info = next_account_info(account_info_iter)?;
    let realm_config_info = next_account_info(account_info_iter)?;
    let mut realm_config_data =
        get_realm_config_data_for_realm(program_id, realm_config_info, realm_info.key)?;
    realm_config_data.assert_can_change_config(&realm_config_args)?;
    let community_token_config = resolve_governing_token_config(
        account_info_iter,
        &realm_config_args.community_token_config_args,
        Some(realm_config_data.community_token_config.clone()),
    )?;
    let council_token_config = resolve_governing_token_config(
        account_info_iter,
        &realm_config_args.council_token_config_args,
        Some(realm_config_data.council_token_config.clone()),
    )?;
    realm_config_data.community_token_config = community_token_config;
    realm_config_data.council_token_config = council_token_config;
    let payer_info = next_account_info(account_info_iter)?;
    let rent = Rent::get()?;
    realm_config_data.serialize(
        program_id,
        realm_config_info,
        payer_info,
        system_info,
        &rent,
    )?;
    realm_data.config.community_mint_max_voter_weight_source =
        realm_config_args.community_mint_max_voter_weight_source;
    realm_data.config.min_community_weight_to_create_governance =
        realm_config_args.min_community_weight_to_create_governance;
    realm_data.config.legacy1 = 0;
    realm_data.config.legacy2 = 0;
    realm_data.serialize(&mut realm_info.data.borrow_mut()[..])?;
    Ok(())
}