#![allow(clippy::arithmetic_side_effects)]
use {
    num_traits::{CheckedShl, CheckedShr, PrimInt},
    std::cmp::Ordering,
};
pub fn sqrt<T: PrimInt + CheckedShl + CheckedShr>(radicand: T) -> Option<T> {
    match radicand.cmp(&T::zero()) {
        Ordering::Less => return None,
        Ordering::Equal => return Some(T::zero()),
        _ => {}
    }
    let max_shift: u32 = T::zero().leading_zeros() - 1;
    let shift: u32 = (max_shift - radicand.leading_zeros()) & !1;
    let mut bit = T::one().checked_shl(shift)?;
    let mut n = radicand;
    let mut result = T::zero();
    while bit != T::zero() {
        let result_with_bit = result.checked_add(&bit)?;
        if n >= result_with_bit {
            n = n.checked_sub(&result_with_bit)?;
            result = result.checked_shr(1)?.checked_add(&bit)?;
        } else {
            result = result.checked_shr(1)?;
        }
        bit = bit.checked_shr(2)?;
    }
    Some(result)
}
#[inline(never)]
pub fn f32_normal_cdf(argument: f32) -> f32 {
    const PI: f32 = std::f32::consts::PI;
    let mod_argument = if argument < 0.0 {
        -1.0 * argument
    } else {
        argument
    };
    let tabulation_numerator: f32 =
        (1.0 / (1.0 * (2.0 * PI).sqrt())) * (-1.0 * (mod_argument * mod_argument) / 2.0).exp();
    let tabulation_denominator: f32 =
        0.226 + 0.64 * mod_argument + 0.33 * (mod_argument * mod_argument + 3.0).sqrt();
    let y: f32 = 1.0 - tabulation_numerator / tabulation_denominator;
    if argument < 0.0 {
        1.0 - y
    } else {
        y
    }
}