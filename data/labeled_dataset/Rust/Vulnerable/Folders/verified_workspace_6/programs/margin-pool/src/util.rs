use anchor_lang::solana_program::clock::UnixTimestamp;
use jet_proto_math::Number;
pub const SECONDS_PER_HOUR: UnixTimestamp = 3600;
pub const SECONDS_PER_2H: UnixTimestamp = SECONDS_PER_HOUR * 2;
pub const SECONDS_PER_12H: UnixTimestamp = SECONDS_PER_HOUR * 12;
pub const SECONDS_PER_DAY: UnixTimestamp = SECONDS_PER_HOUR * 24;
pub const SECONDS_PER_WEEK: UnixTimestamp = SECONDS_PER_DAY * 7;
pub const SECONDS_PER_YEAR: UnixTimestamp = 31_536_000;
pub const MAX_ACCRUAL_SECONDS: UnixTimestamp = SECONDS_PER_WEEK;
static_assertions::const_assert_eq!(SECONDS_PER_HOUR, 60 * 60);
static_assertions::const_assert_eq!(SECONDS_PER_2H, 60 * 60 * 2);
static_assertions::const_assert_eq!(SECONDS_PER_12H, 60 * 60 * 12);
static_assertions::const_assert_eq!(SECONDS_PER_DAY, 60 * 60 * 24);
static_assertions::const_assert_eq!(SECONDS_PER_WEEK, 60 * 60 * 24 * 7);
static_assertions::const_assert_eq!(SECONDS_PER_YEAR, 60 * 60 * 24 * 365);
pub fn compound_interest(rate: Number, seconds: UnixTimestamp) -> Number {
    if rate > Number::ONE * 2 {
        panic!("Not implemented; interest rate too large for compound_interest()");
    }
    let terms = match seconds {
        _ if seconds <= SECONDS_PER_2H => 5,
        _ if seconds <= SECONDS_PER_12H => 6,
        _ if seconds <= SECONDS_PER_DAY => 7,
        _ if seconds <= SECONDS_PER_WEEK => 10,
        _ => panic!("Not implemented; too many seconds in compound_interest()"),
    };
    let x = rate * seconds / SECONDS_PER_YEAR;
    jet_proto_math::expm1_approx(x, terms)
}
pub fn interpolate(x: Number, x0: Number, x1: Number, y0: Number, y1: Number) -> Number {
    assert!(x >= x0);
    assert!(x <= x1);
    y0 + ((x - x0) * (y1 - y0)) / (x1 - x0)
}