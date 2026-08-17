#![allow(clippy::arithmetic_side_effects)]
#![deny(missing_docs)]
pub mod constraints;
pub mod curve;
pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;
#[cfg(not(feature = "no-entrypoint"))]
mod entrypoint;
pub use solana_program;
solana_program::declare_id!("SwapsVeCiPHMUAtzQWZw7RjsKjgCjhwU55QGu4U1Szw");