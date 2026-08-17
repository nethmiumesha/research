use anchor_lang::prelude::*;
use crate::models::TargetState;
pub fn validate_and_assign_balance(state: &mut Account<TargetState>, value: u64) -> Result<()> {
    if value > 0 {
        state.token_treasury = value;
        state.is_active_flag = true;
    }
    Ok(())
}