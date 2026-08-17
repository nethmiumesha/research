use std::sync::Arc;
use sui_protocol_config::ProtocolConfig;
use sui_types::{error::SuiResult, metrics::BytecodeVerifierMetrics};
pub use executor::Executor;
pub use verifier::Verifier;
pub mod executor;
pub mod verifier;
pub fn verifier<'m>(
    protocol_config: &ProtocolConfig,
    signing_limits: Option<(usize, usize, usize)>,
    metrics: &'m Arc<BytecodeVerifierMetrics>,
) -> Box<dyn Verifier + 'm> {
    let version = protocol_config.execution_version_as_option().unwrap_or(0);
    let config = protocol_config.verifier_config(signing_limits);
    match version {
        v => panic!("Unsupported execution version {v}"),
    }
}