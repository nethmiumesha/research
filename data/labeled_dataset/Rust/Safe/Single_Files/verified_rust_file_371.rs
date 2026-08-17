use anchor_lang::prelude::*;
use anchor_spl::token::Mint;
#[account]
pub struct ProgramState {
    pub authority: Pubkey,
    pub total_minted: u64,
    pub max_supply: u64,
    pub next_token_id: u64,
    pub bump: u8,
    pub created_at: i64,
}
#[account]
pub struct ZetaChainGatewayState {
    pub gateway_address: [u8; 20],
    pub supported_chains: Vec<u64>,
    pub version: u8,
    pub updated_at: i64,
    pub bump: u8,
}
#[account]
pub struct NFTMetadata {
    pub mint: Pubkey,
    pub owner: Pubkey,
    pub metadata_uri: String,
    pub zeta_chain_id: u64,
    pub cross_chain_data_hash: [u8; 32],
    pub token_id: u64,
    pub created_at: i64,
    pub updated_at: i64,
    pub bump: u8,
}
#[account]
pub struct NFTOrigin {
    pub token_id: u64,
    pub original_mint: Pubkey,
    pub original_metadata_uri: String,
    pub source_chain_id: u64,
    pub created_at: i64,
    pub bump: u8,
}
#[account]
pub struct CrossChainTransferState {
    pub nft_mint: Pubkey,
    pub token_id: u64,
    pub source_chain_id: u64,
    pub target_chain_id: u64,
    pub recipient: Vec<u8>,
    pub status: TransferStatus,
    pub zeta_tx_hash: [u8; 32],
    pub created_at: i64,
    pub bump: u8,
}
#[account]
pub struct OwnershipVerificationState {
    pub nft_mint: Pubkey,
    pub zeta_owner: Vec<u8>,
    pub proof_hash: [u8; 32],
    pub verified: bool,
    pub verified_at: i64,
    pub bump: u8,
}
#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub enum TransferStatus {
    Pending = 0,
    InProgress = 1,
    Completed = 2,
    Failed = 3,
}
impl ProgramState {
    pub const LEN: usize = 8 +
        32 +
        8 +
        8 +
        8 +
        1 +
        8;
}
impl ZetaChainGatewayState {
    pub const LEN: usize = 8 +
        20 +
        4 + 13 * 8 +
        1 +
        8 +
        1;
}
impl NFTMetadata {
    pub const LEN: usize = 8 +
        32 +
        32 +
        4 + 200 +
        8 +
        32 +
        8 +
        8 +
        8 +
        1;
}
impl NFTOrigin {
    pub const LEN: usize = 8 +
        8 +
        32 +
        4 + 200 +
        8 +
        8 +
        1;
}
impl CrossChainTransferState {
    pub const LEN: usize = 8 +
        32 +
        8 +
        8 +
        8 +
        4 + 100 +
        1 +
        32 +
        8 +
        1;
}
impl OwnershipVerificationState {
    pub const LEN: usize = 8 +
        32 +
        4 + 100 +
        32 +
        1 +
        8 +
        1;
}