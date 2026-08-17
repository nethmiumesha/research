#![deny(missing_docs)]
#![forbid(unsafe_code)]
pub mod processor;
#[cfg(not(feature = "no-entrypoint"))]
mod entrypoint;