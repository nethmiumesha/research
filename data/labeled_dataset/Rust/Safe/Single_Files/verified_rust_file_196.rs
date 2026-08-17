use {
    crate::error::SwapError,
    arrayref::{array_mut_ref, array_ref, array_refs, mut_array_refs},
    solana_program::{
        program_error::ProgramError,
        program_pack::{IsInitialized, Pack, Sealed},
    },
};
#[derive(Clone, Debug, Default, PartialEq)]
pub struct Fees {
    pub trade_fee_numerator: u64,
    pub trade_fee_denominator: u64,
    pub owner_trade_fee_numerator: u64,
    pub owner_trade_fee_denominator: u64,
    pub owner_withdraw_fee_numerator: u64,
    pub owner_withdraw_fee_denominator: u64,
    pub host_fee_numerator: u64,
    pub host_fee_denominator: u64,
}
pub fn calculate_fee(
    token_amount: u128,
    fee_numerator: u128,
    fee_denominator: u128,
) -> Option<u128> {
    if fee_numerator == 0 || token_amount == 0 {
        Some(0)
    } else {
        let fee = token_amount
            .checked_mul(fee_numerator)?
            .checked_div(fee_denominator)?;
        if fee == 0 {
            Some(1)
        } else {
            Some(fee)
        }
    }
}
fn ceil_div(dividend: u128, divisor: u128) -> Option<u128> {
    dividend
        .checked_add(divisor)?
        .checked_sub(1)?
        .checked_div(divisor)
}
fn pre_fee_amount(
    post_fee_amount: u128,
    fee_numerator: u128,
    fee_denominator: u128,
) -> Option<u128> {
    if fee_numerator == 0 || fee_denominator == 0 {
        Some(post_fee_amount)
    } else if fee_numerator == fee_denominator || post_fee_amount == 0 {
        Some(0)
    } else {
        let numerator = post_fee_amount.checked_mul(fee_denominator)?;
        let denominator = fee_denominator.checked_sub(fee_numerator)?;
        ceil_div(numerator, denominator)
    }
}
fn validate_fraction(numerator: u64, denominator: u64) -> Result<(), SwapError> {
    if denominator == 0 && numerator == 0 {
        Ok(())
    } else if numerator >= denominator {
        Err(SwapError::InvalidFee)
    } else {
        Ok(())
    }
}
impl Fees {
    pub fn owner_withdraw_fee(&self, pool_tokens: u128) -> Option<u128> {
        calculate_fee(
            pool_tokens,
            u128::from(self.owner_withdraw_fee_numerator),
            u128::from(self.owner_withdraw_fee_denominator),
        )
    }
    pub fn trading_fee(&self, trading_tokens: u128) -> Option<u128> {
        calculate_fee(
            trading_tokens,
            u128::from(self.trade_fee_numerator),
            u128::from(self.trade_fee_denominator),
        )
    }
    pub fn owner_trading_fee(&self, trading_tokens: u128) -> Option<u128> {
        calculate_fee(
            trading_tokens,
            u128::from(self.owner_trade_fee_numerator),
            u128::from(self.owner_trade_fee_denominator),
        )
    }
    pub fn pre_trading_fee_amount(&self, post_fee_amount: u128) -> Option<u128> {
        if self.trade_fee_numerator == 0 || self.trade_fee_denominator == 0 {
            pre_fee_amount(
                post_fee_amount,
                self.owner_trade_fee_numerator as u128,
                self.owner_trade_fee_denominator as u128,
            )
        } else if self.owner_trade_fee_numerator == 0 || self.owner_trade_fee_denominator == 0 {
            pre_fee_amount(
                post_fee_amount,
                self.trade_fee_numerator as u128,
                self.trade_fee_denominator as u128,
            )
        } else {
            pre_fee_amount(
                post_fee_amount,
                (self.trade_fee_numerator as u128)
                    .checked_mul(self.owner_trade_fee_denominator as u128)?
                    .checked_add(
                        (self.owner_trade_fee_numerator as u128)
                            .checked_mul(self.trade_fee_denominator as u128)?,
                    )?,
                (self.trade_fee_denominator as u128)
                    .checked_mul(self.owner_trade_fee_denominator as u128)?,
            )
        }
    }
    pub fn host_fee(&self, owner_fee: u128) -> Option<u128> {
        calculate_fee(
            owner_fee,
            u128::from(self.host_fee_numerator),
            u128::from(self.host_fee_denominator),
        )
    }
    pub fn validate(&self) -> Result<(), SwapError> {
        validate_fraction(self.trade_fee_numerator, self.trade_fee_denominator)?;
        validate_fraction(
            self.owner_trade_fee_numerator,
            self.owner_trade_fee_denominator,
        )?;
        validate_fraction(
            self.owner_withdraw_fee_numerator,
            self.owner_withdraw_fee_denominator,
        )?;
        validate_fraction(self.host_fee_numerator, self.host_fee_denominator)?;
        Ok(())
    }
}
impl IsInitialized for Fees {
    fn is_initialized(&self) -> bool {
        true
    }
}
impl Sealed for Fees {}
impl Pack for Fees {
    const LEN: usize = 64;
    fn pack_into_slice(&self, output: &mut [u8]) {
        let output = array_mut_ref![output, 0, 64];
        let (
            trade_fee_numerator,
            trade_fee_denominator,
            owner_trade_fee_numerator,
            owner_trade_fee_denominator,
            owner_withdraw_fee_numerator,
            owner_withdraw_fee_denominator,
            host_fee_numerator,
            host_fee_denominator,
        ) = mut_array_refs![output, 8, 8, 8, 8, 8, 8, 8, 8];
        *trade_fee_numerator = self.trade_fee_numerator.to_le_bytes();
        *trade_fee_denominator = self.trade_fee_denominator.to_le_bytes();
        *owner_trade_fee_numerator = self.owner_trade_fee_numerator.to_le_bytes();
        *owner_trade_fee_denominator = self.owner_trade_fee_denominator.to_le_bytes();
        *owner_withdraw_fee_numerator = self.owner_withdraw_fee_numerator.to_le_bytes();
        *owner_withdraw_fee_denominator = self.owner_withdraw_fee_denominator.to_le_bytes();
        *host_fee_numerator = self.host_fee_numerator.to_le_bytes();
        *host_fee_denominator = self.host_fee_denominator.to_le_bytes();
    }
    fn unpack_from_slice(input: &[u8]) -> Result<Fees, ProgramError> {
        let input = array_ref![input, 0, 64];
        #[allow(clippy::ptr_offset_with_cast)]
        let (
            trade_fee_numerator,
            trade_fee_denominator,
            owner_trade_fee_numerator,
            owner_trade_fee_denominator,
            owner_withdraw_fee_numerator,
            owner_withdraw_fee_denominator,
            host_fee_numerator,
            host_fee_denominator,
        ) = array_refs![input, 8, 8, 8, 8, 8, 8, 8, 8];
        Ok(Self {
            trade_fee_numerator: u64::from_le_bytes(*trade_fee_numerator),
            trade_fee_denominator: u64::from_le_bytes(*trade_fee_denominator),
            owner_trade_fee_numerator: u64::from_le_bytes(*owner_trade_fee_numerator),
            owner_trade_fee_denominator: u64::from_le_bytes(*owner_trade_fee_denominator),
            owner_withdraw_fee_numerator: u64::from_le_bytes(*owner_withdraw_fee_numerator),
            owner_withdraw_fee_denominator: u64::from_le_bytes(*owner_withdraw_fee_denominator),
            host_fee_numerator: u64::from_le_bytes(*host_fee_numerator),
            host_fee_denominator: u64::from_le_bytes(*host_fee_denominator),
        })
    }
}