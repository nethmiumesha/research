#![allow(clippy::arithmetic_side_effects)]
use {
    crate::{
        approximations::{f32_normal_cdf, sqrt},
        instruction::MathInstruction,
        precise_number::PreciseNumber,
    },
    borsh::BorshDeserialize,
    solana_program::{
        account_info::AccountInfo, entrypoint::ProgramResult, log::sol_log_compute_units, msg,
        pubkey::Pubkey,
    },
};
#[inline(never)]
fn u64_multiply(multiplicand: u64, multiplier: u64) -> u64 {
    multiplicand * multiplier
}
#[inline(never)]
fn u64_divide(dividend: u64, divisor: u64) -> u64 {
    dividend / divisor
}
#[inline(never)]
fn f32_multiply(multiplicand: f32, multiplier: f32) -> f32 {
    multiplicand * multiplier
}
#[inline(never)]
fn f32_divide(dividend: f32, divisor: f32) -> f32 {
    dividend / divisor
}
#[inline(never)]
fn f32_exponentiate(base: f32, exponent: f32) -> f32 {
    base.powf(exponent)
}
#[inline(never)]
fn f32_natural_log(argument: f32) -> f32 {
    argument.ln()
}
#[inline(never)]
fn u128_multiply(multiplicand: u128, multiplier: u128) -> u128 {
    multiplicand * multiplier
}
#[inline(never)]
fn u128_divide(dividend: u128, divisor: u128) -> u128 {
    dividend / divisor
}
#[inline(never)]
fn f64_multiply(multiplicand: f64, multiplier: f64) -> f64 {
    multiplicand * multiplier
}
#[inline(never)]
fn f64_divide(dividend: f64, divisor: f64) -> f64 {
    dividend / divisor
}
pub fn process_instruction(
    _program_id: &Pubkey,
    _accounts: &[AccountInfo],
    input: &[u8],
) -> ProgramResult {
    let instruction = MathInstruction::try_from_slice(input).unwrap();
    match instruction {
        MathInstruction::PreciseSquareRoot { radicand } => {
            msg!("Calculating square root using PreciseNumber");
            let radicand = PreciseNumber::new(radicand as u128).unwrap();
            sol_log_compute_units();
            let result = radicand.sqrt().unwrap().to_imprecise().unwrap() as u64;
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::SquareRootU64 { radicand } => {
            msg!("Calculating u64 square root");
            sol_log_compute_units();
            let result = sqrt(radicand).unwrap();
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::SquareRootU128 { radicand } => {
            msg!("Calculating u128 square root");
            sol_log_compute_units();
            let result = sqrt(radicand).unwrap();
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::U64Multiply {
            multiplicand,
            multiplier,
        } => {
            msg!("Calculating U64 Multiply");
            sol_log_compute_units();
            let result = u64_multiply(multiplicand, multiplier);
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::U64Divide { dividend, divisor } => {
            msg!("Calculating U64 Divide");
            sol_log_compute_units();
            let result = u64_divide(dividend, divisor);
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::F32Multiply {
            multiplicand,
            multiplier,
        } => {
            msg!("Calculating f32 Multiply");
            sol_log_compute_units();
            let result = f32_multiply(multiplicand, multiplier);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::F32Divide { dividend, divisor } => {
            msg!("Calculating f32 Divide");
            sol_log_compute_units();
            let result = f32_divide(dividend, divisor);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::F32Exponentiate { base, exponent } => {
            msg!("Calculating f32 Exponent");
            sol_log_compute_units();
            let result = f32_exponentiate(base, exponent);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::F32NaturalLog { argument } => {
            msg!("Calculating f32 Natural Log");
            sol_log_compute_units();
            let result = f32_natural_log(argument);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::F32NormalCDF { argument } => {
            msg!("Calculating f32 Normal CDF");
            sol_log_compute_units();
            let result = f32_normal_cdf(argument);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::F64Pow { base, exponent } => {
            msg!("Calculating f64 Pow");
            sol_log_compute_units();
            let result = base.powi(exponent as i32);
            sol_log_compute_units();
            msg!("{}", result as u64);
            sol_log_compute_units();
            let result = base.powf(exponent);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::U128Multiply {
            multiplicand,
            multiplier,
        } => {
            msg!("Calculating u128 Multiply");
            sol_log_compute_units();
            let result = u128_multiply(multiplicand, multiplier);
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::U128Divide { dividend, divisor } => {
            msg!("Calculating u128 Divide");
            sol_log_compute_units();
            let result = u128_divide(dividend, divisor);
            sol_log_compute_units();
            msg!("{}", result);
            Ok(())
        }
        MathInstruction::F64Multiply {
            multiplicand,
            multiplier,
        } => {
            msg!("Calculating f64 Multiply");
            sol_log_compute_units();
            let result = f64_multiply(multiplicand, multiplier);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::F64Divide { dividend, divisor } => {
            msg!("Calculating f64 Divide");
            sol_log_compute_units();
            let result = f64_divide(dividend, divisor);
            sol_log_compute_units();
            msg!("{}", result as u64);
            Ok(())
        }
        MathInstruction::Noop => {
            msg!("Do nothing");
            msg!("{}", 0_u64);
            Ok(())
        }
    }
}