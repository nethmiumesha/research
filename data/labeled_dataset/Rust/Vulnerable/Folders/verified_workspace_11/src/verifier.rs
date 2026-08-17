use move_binary_format::CompiledModule;
use move_bytecode_verifier_meter::Meter;
use move_vm_config::verifier::MeterConfig;
use sui_protocol_config::ProtocolConfig;
use sui_types::error::SuiResult;
pub trait Verifier {
    fn meter(&self, config: MeterConfig) -> Box<dyn Meter>;
    fn override_deprecate_global_storage_ops_during_deserialization(&self) -> Option<bool>;
    fn meter_compiled_modules(
        &mut self,
        protocol_config: &ProtocolConfig,
        modules: &[CompiledModule],
        meter: &mut dyn Meter,
    ) -> SuiResult<()>;
    fn meter_module_bytes(
        &mut self,
        protocol_config: &ProtocolConfig,
        module_bytes: &[Vec<u8>],
        meter: &mut dyn Meter,
    ) -> SuiResult<()> {
        let binary_config = protocol_config
            .binary_config(self.override_deprecate_global_storage_ops_during_deserialization());
        let Ok(modules) = module_bytes
            .iter()
            .map(|b| CompiledModule::deserialize_with_config(b, &binary_config))
            .collect::<Result<Vec<_>, _>>()
        else {
            return Ok(());
        };
        for module in &modules {
            for identifier in module.identifiers() {
                if identifier.as_str() == "<SELF>" {
                    return Err(sui_types::error::UserInputError::InvalidIdentifier {
                        error: format!("invalid identifier: {}", identifier),
                    }
                    .into());
                }
            }
        }
        self.meter_compiled_modules(protocol_config, &modules, meter)
    }
}