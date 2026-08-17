use num_enum::{IntoPrimitive, TryFromPrimitive};
#[derive(Clone, Debug, PartialEq, TryFromPrimitive, IntoPrimitive)]
#[repr(u8)]
pub enum TokenWrapInstruction {
    CreateMint,
    Wrap,
    Unwrap,
}