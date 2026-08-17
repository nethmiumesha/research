#![allow(clippy::arithmetic_side_effects)]
#![allow(clippy::doc_lazy_continuation)]
#![deny(missing_docs)]
pub mod addins;
pub mod entrypoint;
pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;
pub mod tools;
pub use solana_program;
pub const PROGRAM_AUTHORITY_SEED: &[u8] = b"governance";