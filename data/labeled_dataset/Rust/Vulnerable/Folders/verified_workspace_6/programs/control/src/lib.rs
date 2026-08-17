use anchor_lang::prelude::*;
#[cfg(not(feature = "devnet"))]
use anchor_lang::solana_program::pubkey;
use jet_margin_pool::MarginPoolConfig;
mod instructions;
use instructions::*;
pub use instructions::{MarginPoolParams, TokenMetadataParams};
declare_id!("JPCtrLreUqsEbdhtxZ8zpd8wBydKz4nuEjX5u9Eg5H8");
#[cfg(not(feature = "devnet"))]
static ROOT_AUTHORITY: Pubkey = pubkey!("FqXoGb9Zxy4uzG12N1jvHyktNG3Zsez367vAzJeiyMF1");
#[program]
mod jet_control {
    use super::*;
    pub fn create_authority(ctx: Context<CreateAuthority>) -> Result<()> {
        instructions::create_authority_handler(ctx)
    }
    pub fn register_token(ctx: Context<RegisterToken>) -> Result<()> {
        instructions::register_token_handler(ctx)
    }
    pub fn register_adapter(ctx: Context<RegisterAdapter>) -> Result<()> {
        instructions::register_adapter_handler(ctx)
    }
    pub fn configure_token(
        ctx: Context<ConfigureToken>,
        metadata: Option<TokenMetadataParams>,
        pool_param: Option<MarginPoolParams>,
        pool_config: Option<MarginPoolConfig>,
    ) -> Result<()> {
        instructions::configure_token_handler(ctx, metadata, pool_param, pool_config)
    }
}