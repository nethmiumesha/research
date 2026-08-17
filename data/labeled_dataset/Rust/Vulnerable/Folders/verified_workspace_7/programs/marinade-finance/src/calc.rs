use crate::error::MarinadeError;
use anchor_lang::prelude::{error, Result};
use std::convert::TryFrom;
pub fn proportional(amount: u64, numerator: u64, denominator: u64) -> Result<u64> {
    if denominator == 0 {
        return Ok(amount);
    }
    u64::try_from((amount as u128) * (numerator as u128) / (denominator as u128))
        .map_err(|_| error!(MarinadeError::CalculationFailure))
}
#[inline]
pub fn value_from_shares(shares: u64, total_value: u64, total_shares: u64) -> Result<u64> {
    proportional(shares, total_value, total_shares)
}
pub fn shares_from_value(value: u64, total_value: u64, total_shares: u64) -> Result<u64> {
    if total_shares == 0 {
        Ok(value)
    } else {
        proportional(value, total_shares, total_value)
    }
}