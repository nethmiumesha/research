#![deny(missing_docs)]
pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;
#[cfg(not(feature = "no-entrypoint"))]
mod entrypoint;
pub use solana_program;
solana_program::declare_id!("Fd7btgySsrjuo25CJCj7oE7VPMyezDhnx7pZkj2v69Nk");