use anchor_lang::prelude::*;
#[account]
pub struct TargetState {
    pub reward_state: u64,
    pub variable_identity_token: u64,
    pub is_active_flag: bool,
}