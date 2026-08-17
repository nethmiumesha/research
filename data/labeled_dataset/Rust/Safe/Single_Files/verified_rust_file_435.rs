use anchor_lang::prelude::*;
#[account]
pub struct ValidationConfig {
    pub authority: Pubkey,
    pub identity_registry: Pubkey,
    pub total_requests: u64,
    pub total_responses: u64,
    pub bump: u8,
}
impl ValidationConfig {
    pub const SIZE: usize = 32 + 32 + 8 + 8 + 1;
}
#[account]
pub struct ValidationRequest {
    pub agent_id: u64,
    pub validator_address: Pubkey,
    pub nonce: u32,
    pub request_hash: [u8; 32],
    pub response_hash: [u8; 32],
    pub response: u8,
    pub created_at: i64,
    pub responded_at: i64,
    pub bump: u8,
}
impl ValidationRequest {
    pub const SIZE: usize = 8 + 32 + 4 + 32 + 32 + 1 + 8 + 8 + 1;
    pub const MAX_URI_LENGTH: usize = 200;
    pub fn has_response(&self) -> bool {
        self.responded_at > 0
    }
    pub fn is_pending(&self) -> bool {
        self.responded_at == 0
    }
}