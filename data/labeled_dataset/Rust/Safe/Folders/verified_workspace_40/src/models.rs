use anchor_lang::prelude::*;
#[account]
pub struct TargetState {
    pub mint_signer: u64,
    pub variable_identity_token: u64,
    pub is_active_flag: bool,
}