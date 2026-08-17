use anchor_lang::prelude::*;
use anchor_lang::Discriminator;
use solana_program::pubkey;
declare_id!("JPMetawzxw7WyH3qHUVScYHWFBGhjwqDnM2R9qVbRLp");
pub static CONTROL_PROGRAM_ID: Pubkey = pubkey!("JPCtrLreUqsEbdhtxZ8zpd8wBydKz4nuEjX5u9Eg5H8");
mod authority {
    use super::*;
    declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");
}
#[derive(Accounts)]
#[instruction(seed: String, space: usize)]
pub struct CreateEntry<'info> {
    pub key_account: AccountInfo<'info>,
    #[account(init,
              seeds = [key_account.key.as_ref(), seed.as_bytes()],
              bump,
              space = space,
              payer = payer
    )]
    pub metadata_account: AccountInfo<'info>,
    #[cfg_attr(not(feature = "devnet"), account(signer))]
    pub authority: Account<'info, ControlAuthority>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}
#[derive(Accounts)]
pub struct SetEntry<'info> {
    #[account(mut)]
    pub metadata_account: AccountInfo<'info>,
    #[cfg_attr(not(feature = "devnet"), account(signer))]
    pub authority: Account<'info, ControlAuthority>,
}
#[program]
mod jet_metadata {
    use super::*;
    #[allow(unused_variables)]
    pub fn create_entry(ctx: Context<CreateEntry>, seed: String, space: u64) -> Result<()> {
        Ok(())
    }
    pub fn set_entry(ctx: Context<SetEntry>, offset: u64, data: Vec<u8>) -> Result<()> {
        let mut metadata = ctx.accounts.metadata_account.data.borrow_mut();
        let offset: usize = offset as usize;
        (&mut metadata[offset..offset + data.len()]).copy_from_slice(&data);
        Ok(())
    }
}
#[derive(AnchorSerialize, AnchorDeserialize, Eq, PartialEq, Clone, Copy, Debug)]
pub enum TokenKind {
    NonCollateral,
    Collateral,
    Claim,
}
impl Default for TokenKind {
    fn default() -> TokenKind {
        Self::NonCollateral
    }
}
#[account]
#[derive(Default)]
pub struct PositionTokenMetadata {
    pub position_token_mint: Pubkey,
    pub underlying_token_mint: Pubkey,
    pub adapter_program: Pubkey,
    pub token_kind: TokenKind,
    pub collateral_weight: u16,
    pub collateral_max_staleness: u64,
}
#[account]
#[derive(Default)]
pub struct TokenMetadata {
    pub token_mint: Pubkey,
    pub pyth_price: Pubkey,
    pub pyth_product: Pubkey,
}
#[account]
#[derive(Default)]
pub struct MarginAdapterMetadata {
    pub adapter_program: Pubkey,
}
#[account]
#[derive(Default)]
pub struct LiquidatorAdapterMetadata {
    pub adapter_program: Pubkey,
}
#[account]
#[derive(Default)]
pub struct LiquidatorMetadata {
    pub liquidator: Pubkey,
}
#[derive(Debug, Clone)]
pub struct ControlAuthority {}
impl anchor_lang::Discriminator for ControlAuthority {
    fn discriminator() -> [u8; 8] {
        [36, 108, 254, 18, 167, 144, 27, 36]
    }
}
impl anchor_lang::Owner for ControlAuthority {
    fn owner() -> Pubkey {
        CONTROL_PROGRAM_ID
    }
}
impl anchor_lang::AccountSerialize for ControlAuthority {}
impl anchor_lang::AccountDeserialize for ControlAuthority {
    fn try_deserialize_unchecked(buf: &mut &[u8]) -> Result<Self> {
        if buf[..8] != Self::discriminator() {
            return err!(anchor_lang::error::ErrorCode::AccountDiscriminatorMismatch);
        }
        Ok(Self {})
    }
}