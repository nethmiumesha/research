use std::cmp::Ordering;
use anchor_lang::{prelude::*, solana_program::clock::UnixTimestamp};
use jet_proto_math::Number;
use pyth_client::Price;
use crate::{util, Amount, AmountKind, ErrorCode};
#[account]
#[repr(C, align(8))]
#[derive(Default)]
pub struct MarginPool {
    pub version: u8,
    pub pool_bump: [u8; 1],
    pub vault: Pubkey,
    pub fee_destination: Pubkey,
    pub deposit_note_mint: Pubkey,
    pub loan_note_mint: Pubkey,
    pub token_mint: Pubkey,
    pub token_price_oracle: Pubkey,
    pub address: Pubkey,
    pub config: MarginPoolConfig,
    pub borrowed_tokens: [u8; 24],
    pub uncollected_fees: [u8; 24],
    pub deposit_tokens: u64,
    pub deposit_notes: u64,
    pub loan_notes: u64,
    pub accrued_until: i64,
}
impl MarginPool {
    pub fn signer_seeds(&self) -> Result<[&[u8]; 2]> {
        if self.flags().contains(PoolFlags::DISABLED) {
            msg!("the pool is currently disabled");
            return err!(ErrorCode::Disabled);
        }
        Ok([self.token_mint.as_ref(), self.pool_bump.as_ref()])
    }
    pub fn deposit(&mut self, amount: &FullAmount) {
        self.deposit_tokens = self.deposit_tokens.checked_add(amount.tokens).unwrap();
        self.deposit_notes = self.deposit_notes.checked_add(amount.notes).unwrap();
    }
    pub fn withdraw(&mut self, amount: &FullAmount) -> Result<()> {
        self.deposit_tokens = self
            .deposit_tokens
            .checked_sub(amount.tokens)
            .ok_or(ErrorCode::InsufficientLiquidity)?;
        self.deposit_notes = self
            .deposit_notes
            .checked_sub(amount.notes)
            .ok_or(ErrorCode::InsufficientLiquidity)?;
        Ok(())
    }
    pub fn borrow(&mut self, amount: &FullAmount) -> Result<()> {
        if !self.flags().contains(PoolFlags::ALLOW_LENDING) {
            msg!("this pool only allows deposits");
            return err!(ErrorCode::DepositsOnly);
        }
        self.deposit_tokens = self
            .deposit_tokens
            .checked_sub(amount.tokens)
            .ok_or(ErrorCode::InsufficientLiquidity)?;
        self.loan_notes = self.loan_notes.checked_add(amount.notes).unwrap();
        *self.total_borrowed_mut() += Number::from(amount.tokens);
        Ok(())
    }
    pub fn repay(&mut self, amount: &FullAmount) -> Result<()> {
        self.deposit_tokens = self.deposit_tokens.checked_add(amount.tokens).unwrap();
        self.loan_notes = self
            .loan_notes
            .checked_sub(amount.notes)
            .ok_or(ErrorCode::InsufficientLiquidity)?;
        *self.total_borrowed_mut() -= Number::from(amount.tokens);
        Ok(())
    }
    pub fn accrue_interest(&mut self, time: UnixTimestamp) -> bool {
        let time_behind = time - self.accrued_until;
        let time_to_accrue = std::cmp::min(time_behind, util::MAX_ACCRUAL_SECONDS);
        match time_to_accrue.cmp(&0) {
            Ordering::Less => panic!("Interest may not be accrued over a negative time period."),
            Ordering::Equal => true,
            Ordering::Greater => {
                let interest_rate = self.interest_rate();
                let compound_rate = util::compound_interest(interest_rate, time_to_accrue);
                let interest_fee_rate = Number::from_bps(self.config.management_fee_rate);
                let new_interest_accrued = *self.total_borrowed() * compound_rate;
                let fee_to_collect = new_interest_accrued * interest_fee_rate;
                *self.total_borrowed_mut() += new_interest_accrued;
                *self.total_uncollected_fees_mut() += fee_to_collect;
                self.accrued_until = self.accrued_until.checked_add(time_to_accrue).unwrap();
                time_behind == time_to_accrue
            }
        }
    }
    pub fn interest_rate(&self) -> Number {
        let borrow_1 = Number::from_bps(self.config.borrow_rate_1);
        if self.deposit_notes == 0 {
            return borrow_1;
        }
        let util_rate = self.utilization_rate();
        let util_1 = Number::from_bps(self.config.utilization_rate_1);
        if util_rate <= util_1 {
            let borrow_0 = Number::from_bps(self.config.borrow_rate_0);
            return util::interpolate(util_rate, Number::ZERO, util_1, borrow_0, borrow_1);
        }
        let util_2 = Number::from_bps(self.config.utilization_rate_2);
        let borrow_2 = Number::from_bps(self.config.borrow_rate_2);
        if util_rate <= util_2 {
            let borrow_1 = Number::from_bps(self.config.borrow_rate_1);
            return util::interpolate(util_rate, util_1, util_2, borrow_1, borrow_2);
        }
        let borrow_3 = Number::from_bps(self.config.borrow_rate_3);
        if util_rate < Number::ONE {
            return util::interpolate(util_rate, util_2, Number::ONE, borrow_2, borrow_3);
        }
        borrow_3
    }
    pub fn utilization_rate(&self) -> Number {
        *self.total_borrowed() / self.total_value()
    }
    pub fn collect_accrued_fees(&mut self) -> u64 {
        let threshold = Number::from(self.config.management_fee_collect_threshold);
        let uncollected = *self.total_uncollected_fees();
        if uncollected < threshold {
            return 0;
        }
        let fee_notes = (uncollected / self.deposit_note_exchange_rate()).as_u64(0);
        *self.total_uncollected_fees_mut() = Number::ZERO;
        self.deposit_notes = self.deposit_notes.checked_add(fee_notes).unwrap();
        fee_notes
    }
    pub fn calculate_prices(&self, pyth_price: &Price) -> PriceResult {
        let price_value = Number::from_decimal(pyth_price.agg.price, pyth_price.expo);
        let twap_value = Number::from_decimal(pyth_price.twap.val, pyth_price.expo);
        let conf_value = Number::from_decimal(pyth_price.agg.conf, pyth_price.expo);
        let deposit_note_price = (price_value * self.deposit_note_exchange_rate())
            .as_u64_rounded(pyth_price.expo) as i64;
        let deposit_note_conf =
            (conf_value * self.deposit_note_exchange_rate()).as_u64_rounded(pyth_price.expo) as u64;
        let deposit_note_twap =
            (twap_value * self.deposit_note_exchange_rate()).as_u64_rounded(pyth_price.expo) as i64;
        let loan_note_price =
            (price_value * self.loan_note_exchange_rate()).as_u64_rounded(pyth_price.expo) as i64;
        let loan_note_conf =
            (conf_value * self.loan_note_exchange_rate()).as_u64_rounded(pyth_price.expo) as u64;
        let loan_note_twap =
            (twap_value * self.loan_note_exchange_rate()).as_u64_rounded(pyth_price.expo) as i64;
        PriceResult {
            deposit_note_price,
            deposit_note_conf,
            deposit_note_twap,
            loan_note_price,
            loan_note_conf,
            loan_note_twap,
        }
    }
    pub fn convert_deposit_amount(
        &self,
        amount: Amount,
        rounding: RoundingDirection,
    ) -> Result<FullAmount> {
        self.convert_amount(amount, self.deposit_note_exchange_rate(), rounding)
    }
    pub fn convert_loan_amount(
        &self,
        amount: Amount,
        rounding: RoundingDirection,
    ) -> Result<FullAmount> {
        self.convert_amount(amount, self.loan_note_exchange_rate(), rounding)
    }
    fn convert_amount(
        &self,
        amount: Amount,
        exchange_rate: Number,
        rounding: RoundingDirection,
    ) -> Result<FullAmount> {
        let amount = match amount.kind {
            AmountKind::Tokens => FullAmount {
                tokens: amount.value,
                notes: match rounding {
                    RoundingDirection::Down => {
                        (Number::from(amount.value) / exchange_rate).as_u64(0)
                    }
                    RoundingDirection::Up => {
                        (Number::from(amount.value) / exchange_rate).as_u64_ceil(0)
                    }
                },
            },
            AmountKind::Notes => FullAmount {
                notes: amount.value,
                tokens: match rounding {
                    RoundingDirection::Down => {
                        (Number::from(amount.value) * exchange_rate).as_u64(0)
                    }
                    RoundingDirection::Up => {
                        (Number::from(amount.value) * exchange_rate).as_u64_ceil(0)
                    }
                },
            },
        };
        if (amount.notes == 0 && amount.tokens > 0) || (amount.tokens == 0 && amount.notes > 0) {
            return err!(crate::ErrorCode::InvalidAmount);
        }
        Ok(amount)
    }
    fn deposit_note_exchange_rate(&self) -> Number {
        let deposit_notes = std::cmp::max(1, self.deposit_notes);
        let total_value = std::cmp::max(Number::ONE, self.total_value());
        (total_value - *self.total_uncollected_fees()) / Number::from(deposit_notes)
    }
    fn loan_note_exchange_rate(&self) -> Number {
        let loan_notes = std::cmp::max(1, self.loan_notes);
        let total_borrowed = std::cmp::max(Number::ONE, *self.total_borrowed());
        total_borrowed / Number::from(loan_notes)
    }
    fn total_value(&self) -> Number {
        *self.total_borrowed() + Number::from(self.deposit_tokens)
    }
    fn total_uncollected_fees_mut(&mut self) -> &mut Number {
        bytemuck::from_bytes_mut(&mut self.uncollected_fees)
    }
    fn total_uncollected_fees(&self) -> &Number {
        bytemuck::from_bytes(&self.uncollected_fees)
    }
    fn total_borrowed_mut(&mut self) -> &mut Number {
        bytemuck::from_bytes_mut(&mut self.borrowed_tokens)
    }
    fn total_borrowed(&self) -> &Number {
        bytemuck::from_bytes(&self.borrowed_tokens)
    }
    fn flags(&self) -> PoolFlags {
        PoolFlags::from_bits_truncate(self.config.flags)
    }
}
#[derive(Debug)]
pub struct FullAmount {
    pub tokens: u64,
    pub notes: u64,
}
#[derive(Clone, Copy)]
pub enum PoolAction {
    Borrow,
    Deposit,
    Repay,
    Withdraw,
}
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RoundingDirection {
    Down,
    Up,
}
impl RoundingDirection {
    pub const fn direction(pool_action: PoolAction, amount_kind: AmountKind) -> Self {
        use RoundingDirection::*;
        match (pool_action, amount_kind) {
            (PoolAction::Borrow, AmountKind::Tokens)
            | (PoolAction::Deposit, AmountKind::Notes)
            | (PoolAction::Repay, AmountKind::Notes)
            | (PoolAction::Withdraw, AmountKind::Tokens) => Up,
            (PoolAction::Borrow, AmountKind::Notes)
            | (PoolAction::Deposit, AmountKind::Tokens)
            | (PoolAction::Repay, AmountKind::Tokens)
            | (PoolAction::Withdraw, AmountKind::Notes) => Down,
        }
    }
}
pub struct PriceResult {
    pub deposit_note_price: i64,
    pub deposit_note_conf: u64,
    pub deposit_note_twap: i64,
    pub loan_note_price: i64,
    pub loan_note_conf: u64,
    pub loan_note_twap: i64,
}
#[derive(Default, AnchorDeserialize, AnchorSerialize, Clone)]
pub struct MarginPoolConfig {
    pub flags: u64,
    pub utilization_rate_1: u16,
    pub utilization_rate_2: u16,
    pub borrow_rate_0: u16,
    pub borrow_rate_1: u16,
    pub borrow_rate_2: u16,
    pub borrow_rate_3: u16,
    pub management_fee_rate: u16,
    pub management_fee_collect_threshold: u64,
}
bitflags::bitflags! {
    pub struct PoolFlags: u64 {
        const DISABLED = 1 << 0;
        const ALLOW_LENDING = 1 << 1;
    }
}
#[account]
pub struct MarginPoolOracle {
    token_mint: Pubkey,
    price: [u8; 24],
    price_lower: [u8; 24],
    price_upper: [u8; 24],
}