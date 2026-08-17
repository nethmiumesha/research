use anchor_lang::prelude::*;
use std::convert::TryInto;
use jet_metadata::cpi::accounts::{CreateEntry, SetEntry};
use jet_metadata::program::JetMetadata;
use jet_metadata::MarginAdapterMetadata;
use super::Authority;
#[derive(Accounts)]
pub struct RegisterAdapter<'info> {
    #[cfg_attr(not(feature = "devnet"), account(address = crate::ROOT_AUTHORITY))]
    pub requester: Signer<'info>,
    pub authority: Account<'info, Authority>,
    pub adapter: AccountInfo<'info>,
    #[account(mut)]
    pub metadata_account: AccountInfo<'info>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub metadata_program: Program<'info, JetMetadata>,
    pub system_program: Program<'info, System>,
}
impl<'info> RegisterAdapter<'info> {
    fn create_metadata_context(&self) -> CpiContext<'_, '_, '_, 'info, CreateEntry<'info>> {
        CpiContext::new(
            self.metadata_program.to_account_info(),
            CreateEntry {
                key_account: self.adapter.to_account_info(),
                metadata_account: self.metadata_account.to_account_info(),
                authority: self.authority.to_account_info(),
                payer: self.payer.to_account_info(),
                system_program: self.system_program.to_account_info(),
            },
        )
    }
    fn set_metadata_context(&self) -> CpiContext<'_, '_, '_, 'info, SetEntry<'info>> {
        CpiContext::new(
            self.metadata_program.to_account_info(),
            SetEntry {
                metadata_account: self.metadata_account.to_account_info(),
                authority: self.authority.to_account_info(),
            },
        )
    }
}
pub fn register_adapter_handler(ctx: Context<RegisterAdapter>) -> Result<()> {
    let authority = [&ctx.accounts.authority.seed[..]];
    let mut data = vec![];
    let metadata = MarginAdapterMetadata {
        adapter_program: ctx.accounts.adapter.key(),
    };
    metadata.try_serialize(&mut data)?;
    jet_metadata::cpi::create_entry(
        ctx.accounts
            .create_metadata_context()
            .with_signer(&[&authority]),
        String::new(),
        data.len().try_into().unwrap(),
    )?;
    jet_metadata::cpi::set_entry(
        ctx.accounts
            .set_metadata_context()
            .with_signer(&[&authority]),
        0,
        data,
    )?;
    Ok(())
}