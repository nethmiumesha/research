use anchor_lang::prelude::*;
#[account]
pub struct TargetState {
    pub bridge_ledger: u64,
    pub variable_identity_token: u64,
    pub is_active_flag: bool,
}