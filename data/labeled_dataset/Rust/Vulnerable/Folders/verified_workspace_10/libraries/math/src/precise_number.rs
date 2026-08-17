#![allow(clippy::arithmetic_side_effects)]
use crate::uint::U256;
type InnerUint = U256;
pub const ONE: u128 = 1_000_000_000_000;
#[derive(Clone, Debug, PartialEq)]
pub struct PreciseNumber {
    pub value: InnerUint,
}
fn one() -> InnerUint {
    InnerUint::from(ONE)
}
fn zero() -> InnerUint {
    InnerUint::from(0)
}
impl PreciseNumber {
    fn rounding_correction() -> InnerUint {
        InnerUint::from(ONE / 2)
    }
    fn precision() -> InnerUint {
        InnerUint::from(100)
    }
    fn zero() -> Self {
        Self { value: zero() }
    }
    fn one() -> Self {
        Self { value: one() }
    }
    const MAX_APPROXIMATION_ITERATIONS: u128 = 100;
    fn min_pow_base() -> InnerUint {
        InnerUint::from(1)
    }
    fn max_pow_base() -> InnerUint {
        InnerUint::from(2 * ONE)
    }
    pub fn new(value: u128) -> Option<Self> {
        let value = InnerUint::from(value).checked_mul(one())?;
        Some(Self { value })
    }
    pub fn to_imprecise(&self) -> Option<u128> {
        self.value
            .checked_add(Self::rounding_correction())?
            .checked_div(one())
            .map(|v| v.as_u128())
    }
    pub fn almost_eq(&self, rhs: &Self, precision: InnerUint) -> bool {
        let (difference, _) = self.unsigned_sub(rhs);
        difference.value < precision
    }
    pub fn less_than(&self, rhs: &Self) -> bool {
        self.value < rhs.value
    }
    pub fn greater_than(&self, rhs: &Self) -> bool {
        self.value > rhs.value
    }
    pub fn less_than_or_equal(&self, rhs: &Self) -> bool {
        self.value <= rhs.value
    }
    pub fn greater_than_or_equal(&self, rhs: &Self) -> bool {
        self.value >= rhs.value
    }
    pub fn floor(&self) -> Option<Self> {
        let value = self.value.checked_div(one())?.checked_mul(one())?;
        Some(Self { value })
    }
    pub fn ceiling(&self) -> Option<Self> {
        let value = self
            .value
            .checked_add(one().checked_sub(InnerUint::from(1))?)?
            .checked_div(one())?
            .checked_mul(one())?;
        Some(Self { value })
    }
    pub fn checked_div(&self, rhs: &Self) -> Option<Self> {
        if *rhs == Self::zero() {
            return None;
        }
        match self.value.checked_mul(one()) {
            Some(v) => {
                let value = v
                    .checked_add(Self::rounding_correction())?
                    .checked_div(rhs.value)?;
                Some(Self { value })
            }
            None => {
                let value = self
                    .value
                    .checked_add(Self::rounding_correction())?
                    .checked_div(rhs.value)?
                    .checked_mul(one())?;
                Some(Self { value })
            }
        }
    }
    pub fn checked_mul(&self, rhs: &Self) -> Option<Self> {
        match self.value.checked_mul(rhs.value) {
            Some(v) => {
                let value = v
                    .checked_add(Self::rounding_correction())?
                    .checked_div(one())?;
                Some(Self { value })
            }
            None => {
                let value = if self.value >= rhs.value {
                    self.value.checked_div(one())?.checked_mul(rhs.value)?
                } else {
                    rhs.value.checked_div(one())?.checked_mul(self.value)?
                };
                Some(Self { value })
            }
        }
    }
    pub fn checked_add(&self, rhs: &Self) -> Option<Self> {
        let value = self.value.checked_add(rhs.value)?;
        Some(Self { value })
    }
    pub fn checked_sub(&self, rhs: &Self) -> Option<Self> {
        let value = self.value.checked_sub(rhs.value)?;
        Some(Self { value })
    }
    pub fn unsigned_sub(&self, rhs: &Self) -> (Self, bool) {
        match self.value.checked_sub(rhs.value) {
            None => {
                let value = rhs.value.checked_sub(self.value).unwrap();
                (Self { value }, true)
            }
            Some(value) => (Self { value }, false),
        }
    }
    pub fn checked_pow(&self, exponent: u128) -> Option<Self> {
        let value = if exponent.checked_rem(2)? == 0 {
            one()
        } else {
            self.value
        };
        let mut result = Self { value };
        let mut squared_base = self.clone();
        let mut current_exponent = exponent.checked_div(2)?;
        while current_exponent != 0 {
            squared_base = squared_base.checked_mul(&squared_base)?;
            if current_exponent.checked_rem(2)? != 0 {
                result = result.checked_mul(&squared_base)?;
            }
            current_exponent = current_exponent.checked_div(2)?;
        }
        Some(result)
    }
    fn checked_pow_approximation(&self, exponent: &Self, max_iterations: u128) -> Option<Self> {
        assert!(self.value >= Self::min_pow_base());
        assert!(self.value <= Self::max_pow_base());
        let one = Self::one();
        if *exponent == Self::zero() {
            return Some(one);
        }
        let mut precise_guess = one.clone();
        let mut term = precise_guess.clone();
        let (x_minus_a, x_minus_a_negative) = self.unsigned_sub(&precise_guess);
        let exponent_plus_one = exponent.checked_add(&one)?;
        let mut negative = false;
        for k in 1..max_iterations {
            let k = Self::new(k)?;
            let (current_exponent, current_exponent_negative) = exponent_plus_one.unsigned_sub(&k);
            term = term.checked_mul(&current_exponent)?;
            term = term.checked_mul(&x_minus_a)?;
            term = term.checked_div(&k)?;
            if term.value < Self::precision() {
                break;
            }
            if x_minus_a_negative {
                negative = !negative;
            }
            if current_exponent_negative {
                negative = !negative;
            }
            if negative {
                precise_guess = precise_guess.checked_sub(&term)?;
            } else {
                precise_guess = precise_guess.checked_add(&term)?;
            }
        }
        Some(precise_guess)
    }
    #[allow(dead_code)]
    fn checked_pow_fraction(&self, exponent: &Self) -> Option<Self> {
        assert!(self.value >= Self::min_pow_base());
        assert!(self.value <= Self::max_pow_base());
        let whole_exponent = exponent.floor()?;
        let precise_whole = self.checked_pow(whole_exponent.to_imprecise()?)?;
        let (remainder_exponent, negative) = exponent.unsigned_sub(&whole_exponent);
        assert!(!negative);
        if remainder_exponent.value == InnerUint::from(0) {
            return Some(precise_whole);
        }
        let precise_remainder = self
            .checked_pow_approximation(&remainder_exponent, Self::MAX_APPROXIMATION_ITERATIONS)?;
        precise_whole.checked_mul(&precise_remainder)
    }
    fn newtonian_root_approximation(
        &self,
        root: &Self,
        mut guess: Self,
        iterations: u128,
    ) -> Option<Self> {
        let zero = Self::zero();
        if *self == zero {
            return Some(zero);
        }
        if *root == zero {
            return None;
        }
        let one = Self::new(1)?;
        let root_minus_one = root.checked_sub(&one)?;
        let root_minus_one_whole = root_minus_one.to_imprecise()?;
        let mut last_guess = guess.clone();
        let precision = Self::precision();
        for _ in 0..iterations {
            let first_term = root_minus_one.checked_mul(&guess)?;
            let power = guess.checked_pow(root_minus_one_whole);
            let second_term = match power {
                Some(num) => self.checked_div(&num)?,
                None => Self::new(0)?,
            };
            guess = first_term.checked_add(&second_term)?.checked_div(root)?;
            if last_guess.almost_eq(&guess, precision) {
                break;
            } else {
                last_guess = guess.clone();
            }
        }
        Some(guess)
    }
    fn minimum_sqrt_base() -> Self {
        Self {
            value: InnerUint::from(0),
        }
    }
    fn maximum_sqrt_base() -> Self {
        Self::new(u128::MAX).unwrap()
    }
    pub fn sqrt(&self) -> Option<Self> {
        if self.less_than(&Self::minimum_sqrt_base())
            || self.greater_than(&Self::maximum_sqrt_base())
        {
            return None;
        }
        let two = PreciseNumber::new(2)?;
        let one = PreciseNumber::new(1)?;
        let guess = self.checked_add(&one)?.checked_div(&two)?;
        self.newtonian_root_approximation(&two, guess, Self::MAX_APPROXIMATION_ITERATIONS)
    }
}