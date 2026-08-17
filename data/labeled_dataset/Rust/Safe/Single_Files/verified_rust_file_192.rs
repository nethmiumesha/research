#[cfg(feature = "fuzz")]
use arbitrary::Arbitrary;
use {
    crate::curve::{
        calculator::{CurveCalculator, RoundDirection, SwapWithoutFeesResult, TradeDirection},
        constant_price::ConstantPriceCurve,
        constant_product::ConstantProductCurve,
        fees::Fees,
        offset::OffsetCurve,
    },
    arrayref::{array_mut_ref, array_ref, array_refs, mut_array_refs},
    solana_program::{
        program_error::ProgramError,
        program_pack::{Pack, Sealed},
    },
    std::{
        convert::{TryFrom, TryInto},
        fmt::Debug,
        sync::Arc,
    },
};
#[cfg_attr(feature = "fuzz", derive(Arbitrary))]
#[repr(C)]
#[derive(Clone, Copy, Debug, PartialEq)]
pub enum CurveType {
    ConstantProduct,
    ConstantPrice,
    Offset,
}
#[derive(Debug, PartialEq)]
pub struct SwapResult {
    pub new_swap_source_amount: u128,
    pub new_swap_destination_amount: u128,
    pub source_amount_swapped: u128,
    pub destination_amount_swapped: u128,
    pub trade_fee: u128,
    pub owner_fee: u128,
}
#[repr(C)]
#[derive(Debug)]
pub struct SwapCurve {
    pub curve_type: CurveType,
    pub calculator: Arc<dyn CurveCalculator + Sync + Send>,
}
impl SwapCurve {
    pub fn swap(
        &self,
        source_amount: u128,
        swap_source_amount: u128,
        swap_destination_amount: u128,
        trade_direction: TradeDirection,
        fees: &Fees,
    ) -> Option<SwapResult> {
        let trade_fee = fees.trading_fee(source_amount)?;
        let owner_fee = fees.owner_trading_fee(source_amount)?;
        let total_fees = trade_fee.checked_add(owner_fee)?;
        let source_amount_less_fees = source_amount.checked_sub(total_fees)?;
        let SwapWithoutFeesResult {
            source_amount_swapped,
            destination_amount_swapped,
        } = self.calculator.swap_without_fees(
            source_amount_less_fees,
            swap_source_amount,
            swap_destination_amount,
            trade_direction,
        )?;
        let source_amount_swapped = source_amount_swapped.checked_add(total_fees)?;
        Some(SwapResult {
            new_swap_source_amount: swap_source_amount.checked_add(source_amount_swapped)?,
            new_swap_destination_amount: swap_destination_amount
                .checked_sub(destination_amount_swapped)?,
            source_amount_swapped,
            destination_amount_swapped,
            trade_fee,
            owner_fee,
        })
    }
    pub fn deposit_single_token_type(
        &self,
        source_amount: u128,
        swap_token_a_amount: u128,
        swap_token_b_amount: u128,
        pool_supply: u128,
        trade_direction: TradeDirection,
        fees: &Fees,
    ) -> Option<u128> {
        if source_amount == 0 {
            return Some(0);
        }
        let half_source_amount = std::cmp::max(1, source_amount.checked_div(2)?);
        let trade_fee = fees.trading_fee(half_source_amount)?;
        let owner_fee = fees.owner_trading_fee(half_source_amount)?;
        let total_fees = trade_fee.checked_add(owner_fee)?;
        let source_amount = source_amount.checked_sub(total_fees)?;
        self.calculator.deposit_single_token_type(
            source_amount,
            swap_token_a_amount,
            swap_token_b_amount,
            pool_supply,
            trade_direction,
        )
    }
    pub fn withdraw_single_token_type_exact_out(
        &self,
        source_amount: u128,
        swap_token_a_amount: u128,
        swap_token_b_amount: u128,
        pool_supply: u128,
        trade_direction: TradeDirection,
        fees: &Fees,
    ) -> Option<u128> {
        if source_amount == 0 {
            return Some(0);
        }
        let half_source_amount = source_amount.checked_add(1)?.checked_div(2)?;
        let pre_fee_source_amount = fees.pre_trading_fee_amount(half_source_amount)?;
        let source_amount = source_amount
            .checked_sub(half_source_amount)?
            .checked_add(pre_fee_source_amount)?;
        self.calculator.withdraw_single_token_type_exact_out(
            source_amount,
            swap_token_a_amount,
            swap_token_b_amount,
            pool_supply,
            trade_direction,
            RoundDirection::Ceiling,
        )
    }
}
impl Default for SwapCurve {
    fn default() -> Self {
        let curve_type: CurveType = Default::default();
        let calculator: ConstantProductCurve = Default::default();
        Self {
            curve_type,
            calculator: Arc::new(calculator),
        }
    }
}
#[cfg(any(test, feature = "fuzz"))]
impl Clone for SwapCurve {
    fn clone(&self) -> Self {
        let mut packed_self = [0u8; Self::LEN];
        Self::pack_into_slice(self, &mut packed_self);
        Self::unpack_from_slice(&packed_self).unwrap()
    }
}
impl PartialEq for SwapCurve {
    fn eq(&self, other: &Self) -> bool {
        let mut packed_self = [0u8; Self::LEN];
        Self::pack_into_slice(self, &mut packed_self);
        let mut packed_other = [0u8; Self::LEN];
        Self::pack_into_slice(other, &mut packed_other);
        packed_self[..] == packed_other[..]
    }
}
impl Sealed for SwapCurve {}
impl Pack for SwapCurve {
    const LEN: usize = 33;
    fn unpack_from_slice(input: &[u8]) -> Result<Self, ProgramError> {
        let input = array_ref![input, 0, 33];
        #[allow(clippy::ptr_offset_with_cast)]
        let (curve_type, calculator) = array_refs![input, 1, 32];
        let curve_type = curve_type[0].try_into()?;
        Ok(Self {
            curve_type,
            calculator: match curve_type {
                CurveType::ConstantProduct => {
                    Arc::new(ConstantProductCurve::unpack_from_slice(calculator)?)
                }
                CurveType::ConstantPrice => {
                    Arc::new(ConstantPriceCurve::unpack_from_slice(calculator)?)
                }
                CurveType::Offset => Arc::new(OffsetCurve::unpack_from_slice(calculator)?),
            },
        })
    }
    fn pack_into_slice(&self, output: &mut [u8]) {
        let output = array_mut_ref![output, 0, 33];
        let (curve_type, calculator) = mut_array_refs![output, 1, 32];
        curve_type[0] = self.curve_type as u8;
        self.calculator.pack_into_slice(&mut calculator[..]);
    }
}
impl Default for CurveType {
    fn default() -> Self {
        CurveType::ConstantProduct
    }
}
impl TryFrom<u8> for CurveType {
    type Error = ProgramError;
    fn try_from(curve_type: u8) -> Result<Self, Self::Error> {
        match curve_type {
            0 => Ok(CurveType::ConstantProduct),
            1 => Ok(CurveType::ConstantPrice),
            2 => Ok(CurveType::Offset),
            _ => Err(ProgramError::InvalidAccountData),
        }
    }
}