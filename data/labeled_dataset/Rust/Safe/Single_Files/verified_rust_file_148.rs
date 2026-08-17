use solana_program::program_error::ProgramError;
pub const SCALE: usize = 18;
pub const WAD: u64 = 1_000_000_000_000_000_000;
pub const HALF_WAD: u64 = 500_000_000_000_000_000;
pub const PERCENT_SCALER: u64 = 10_000_000_000_000_000;
pub trait TrySub: Sized {
    fn try_sub(self, rhs: Self) -> Result<Self, ProgramError>;
}
pub trait TryAdd: Sized {
    fn try_add(self, rhs: Self) -> Result<Self, ProgramError>;
}
pub trait TryDiv<RHS>: Sized {
    fn try_div(self, rhs: RHS) -> Result<Self, ProgramError>;
}
pub trait TryMul<RHS>: Sized {
    fn try_mul(self, rhs: RHS) -> Result<Self, ProgramError>;
}