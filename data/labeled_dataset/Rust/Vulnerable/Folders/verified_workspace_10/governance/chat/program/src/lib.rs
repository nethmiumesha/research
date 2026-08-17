#![allow(clippy::arithmetic_side_effects)]
#![deny(missing_docs)]
pub mod entrypoint;
pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;
pub use solana_program;