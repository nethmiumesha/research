use {
    crate::{
        curve::{
            calculator::{
                CurveCalculator, DynPack, RoundDirection, SwapWithoutFeesResult, TradeDirection,
                TradingTokenResult,
            },
            constant_product::{
                deposit_single_token_type, normalized_value, pool_tokens_to_trading_tokens, swap,
                withdraw_single_token_type_exact_out,
            },
        },
        error::SwapError,
    },
    arrayref::{array_mut_ref, array_ref},
    solana_program::{
        program_error::ProgramError,
        program_pack::{IsInitialized, Pack, Sealed},
    },
    spl_math::precise_number::PreciseNumber,
};
#[derive(Clone, Debug, Default, PartialEq)]
pub struct OffsetCurve {
    pub token_b_offset: u64,
}
impl CurveCalculator for OffsetCurve {
    fn swap_without_fees(
        &self,
        source_amount: u128,
        swap_source_amount: u128,
        swap_destination_amount: u128,
        trade_direction: TradeDirection,
    ) -> Option<SwapWithoutFeesResult> {
        let token_b_offset = self.token_b_offset as u128;
        let swap_source_amount = match trade_direction {
            TradeDirection::AtoB => swap_source_amount,
            TradeDirection::BtoA => swap_source_amount.checked_add(token_b_offset)?,
        };
        let swap_destination_amount = match trade_direction {
            TradeDirection::AtoB => swap_destination_amount.checked_add(token_b_offset)?,
            TradeDirection::BtoA => swap_destination_amount,
        };
        swap(source_amount, swap_source_amount, swap_destination_amount)
    }
    fn pool_tokens_to_trading_tokens(
        &self,
        pool_tokens: u128,
        pool_token_supply: u128,
        swap_token_a_amount: u128,
        swap_token_b_amount: u128,
        round_direction: RoundDirection,
    ) -> Option<TradingTokenResult> {
        let token_b_offset = self.token_b_offset as u128;
        pool_tokens_to_trading_tokens(
            pool_tokens,
            pool_token_supply,
            swap_token_a_amount,
            swap_token_b_amount.checked_add(token_b_offset)?,
            round_direction,
        )
    }
    fn deposit_single_token_type(
        &self,
        source_amount: u128,
        swap_token_a_amount: u128,
        swap_token_b_amount: u128,
        pool_supply: u128,
        trade_direction: TradeDirection,
    ) -> Option<u128> {
        let token_b_offset = self.token_b_offset as u128;
        deposit_single_token_type(
            source_amount,
            swap_token_a_amount,
            swap_token_b_amount.checked_add(token_b_offset)?,
            pool_supply,
            trade_direction,
            RoundDirection::Floor,
        )
    }
    fn withdraw_single_token_type_exact_out(
        &self,
        source_amount: u128,
        swap_token_a_amount: u128,
        swap_token_b_amount: u128,
        pool_supply: u128,
        trade_direction: TradeDirection,
        round_direction: RoundDirection,
    ) -> Option<u128> {
        let token_b_offset = self.token_b_offset as u128;
        withdraw_single_token_type_exact_out(
            source_amount,
            swap_token_a_amount,
            swap_token_b_amount.checked_add(token_b_offset)?,
            pool_supply,
            trade_direction,
            round_direction,
        )
    }
    fn validate(&self) -> Result<(), SwapError> {
        if self.token_b_offset == 0 {
            Err(SwapError::InvalidCurve)
        } else {
            Ok(())
        }
    }
    fn validate_supply(&self, token_a_amount: u64, _token_b_amount: u64) -> Result<(), SwapError> {
        if token_a_amount == 0 {
            return Err(SwapError::EmptySupply);
        }
        Ok(())
    }
    fn allows_deposits(&self) -> bool {
        false
    }
    fn normalized_value(
        &self,
        swap_token_a_amount: u128,
        swap_token_b_amount: u128,
    ) -> Option<PreciseNumber> {
        let token_b_offset = self.token_b_offset as u128;
        normalized_value(
            swap_token_a_amount,
            swap_token_b_amount.checked_add(token_b_offset)?,
        )
    }
}
impl IsInitialized for OffsetCurve {
    fn is_initialized(&self) -> bool {
        true
    }
}
impl Sealed for OffsetCurve {}
impl Pack for OffsetCurve {
    const LEN: usize = 8;
    fn pack_into_slice(&self, output: &mut [u8]) {
        (self as &dyn DynPack).pack_into_slice(output);
    }
    fn unpack_from_slice(input: &[u8]) -> Result<OffsetCurve, ProgramError> {
        let token_b_offset = array_ref![input, 0, 8];
        Ok(Self {
            token_b_offset: u64::from_le_bytes(*token_b_offset),
        })
    }
}
impl DynPack for OffsetCurve {
    fn pack_into_slice(&self, output: &mut [u8]) {
        let token_b_offset = array_mut_ref![output, 0, 8];
        *token_b_offset = self.token_b_offset.to_le_bytes();
    }
}