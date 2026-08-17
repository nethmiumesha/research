use move_binary_format::file_format::{
    Ability, AbilitySet, Bytecode, CompiledModule, DatatypeHandle, FunctionDefinition,
    FunctionHandle, SignatureToken, StructDefinition,
};
use move_core_types::{ident_str, language_storage::ModuleId};
use sui_types::bridge::BRIDGE_SUPPORTED_ASSET;
use sui_types::{
    BRIDGE_ADDRESS, SUI_FRAMEWORK_ADDRESS,
    base_types::{TX_CONTEXT_MODULE_NAME, TX_CONTEXT_STRUCT_NAME},
    error::ExecutionError,
    move_package::{FnInfoMap, is_test_fun},
};
use crate::{INIT_FN_NAME, verification_failure};
pub fn verify_module(
    module: &CompiledModule,
    fn_info_map: &FnInfoMap,
) -> Result<(), ExecutionError> {
    let self_id = module.self_id();
    if ModuleId::new(SUI_FRAMEWORK_ADDRESS, ident_str!("sui").to_owned()) == self_id {
        return Ok(());
    }
    if BRIDGE_SUPPORTED_ASSET
        .iter()
        .any(|token| ModuleId::new(BRIDGE_ADDRESS, ident_str!(token).to_owned()) == self_id)
    {
        return Ok(());
    }
    let mod_handle = module.module_handle_at(module.self_module_handle_idx);
    let mod_name = module.identifier_at(mod_handle.name).as_str();
    let struct_defs = &module.struct_defs;
    let mut one_time_witness_candidate = None;
    for def in struct_defs {
        let struct_handle = module.datatype_handle_at(def.struct_handle);
        let struct_name = module.identifier_at(struct_handle.name).as_str();
        if mod_name.to_ascii_uppercase() == struct_name {
            if let Ok(field_count) = def.declared_field_count() {
                if field_count == 1 && def.field(0).unwrap().signature.0 == SignatureToken::Bool {
                    verify_one_time_witness(module, struct_name, struct_handle)
                        .map_err(verification_failure)?;
                    one_time_witness_candidate = Some((struct_name, struct_handle, def));
                    break;
                }
            }
        }
    }
    for fn_def in &module.function_defs {
        let fn_handle = module.function_handle_at(fn_def.function);
        let fn_name = module.identifier_at(fn_handle.name);
        if fn_name == INIT_FN_NAME {
            if let Some((candidate_name, candidate_handle, _)) = one_time_witness_candidate {
                verify_init_one_time_witness(module, fn_handle, candidate_name, candidate_handle)
                    .map_err(verification_failure)?;
            } else {
                verify_init_single_param(module, fn_handle).map_err(verification_failure)?;
            }
        }
        if let Some((candidate_name, _, def)) = one_time_witness_candidate {
            if !is_test_fun(fn_name, module, fn_info_map) {
                verify_no_instantiations(module, fn_def, candidate_name, def)
                    .map_err(verification_failure)?;
            }
        }
    }
    Ok(())
}
fn verify_one_time_witness(
    module: &CompiledModule,
    candidate_name: &str,
    candidate_handle: &DatatypeHandle,
) -> Result<(), String> {
    let drop_set = AbilitySet::EMPTY | Ability::Drop;
    let abilities = candidate_handle.abilities;
    if abilities != drop_set {
        return Err(format!(
            "one-time witness type candidate {}::{} must have a single ability: drop",
            module.self_id(),
            candidate_name,
        ));
    }
    if !candidate_handle.type_parameters.is_empty() {
        return Err(format!(
            "one-time witness type candidate {}::{} cannot have type parameters",
            module.self_id(),
            candidate_name,
        ));
    }
    Ok(())
}
fn verify_init_one_time_witness(
    module: &CompiledModule,
    fn_handle: &FunctionHandle,
    candidate_name: &str,
    candidate_handle: &DatatypeHandle,
) -> Result<(), String> {
    let fn_sig = module.signature_at(fn_handle.parameters);
    if fn_sig.len() != 2 || !is_one_time_witness(module, &fn_sig.0[0], candidate_handle) {
        return Err(format!(
            "init function of a module containing one-time witness type candidate must have \
             {}::{} as the first parameter (a struct which has no fields or a single field of type \
             bool)",
            module.self_id(),
            candidate_name,
        ));
    }
    Ok(())
}
fn is_one_time_witness(
    view: &CompiledModule,
    tok: &SignatureToken,
    candidate_handle: &DatatypeHandle,
) -> bool {
    matches!(tok, SignatureToken::Datatype(idx) if view.datatype_handle_at(*idx) == candidate_handle)
}
fn verify_init_single_param(
    module: &CompiledModule,
    fn_handle: &FunctionHandle,
) -> Result<(), String> {
    let fn_sig = module.signature_at(fn_handle.parameters);
    if fn_sig.len() != 1 {
        return Err(format!(
            "Expected last (and at most second) parameter for {0}::{1} to be &mut {2}::{3}::{4} or \
             &{2}::{3}::{4}; optional first parameter must be of one-time witness type whose name \
             is the same as the capitalized module name ({5}::{6}) and which has no fields or a \
             single field of type bool",
            module.self_id(),
            INIT_FN_NAME,
            SUI_FRAMEWORK_ADDRESS,
            TX_CONTEXT_MODULE_NAME,
            TX_CONTEXT_STRUCT_NAME,
            module.self_id(),
            module.self_id().name().as_str().to_uppercase(),
        ));
    }
    Ok(())
}
fn verify_no_instantiations(
    module: &CompiledModule,
    fn_def: &FunctionDefinition,
    struct_name: &str,
    struct_def: &StructDefinition,
) -> Result<(), String> {
    if fn_def.code.is_none() {
        return Ok(());
    }
    for bcode in &fn_def.code.as_ref().unwrap().code {
        let struct_def_idx = match bcode {
            Bytecode::Pack(idx) => idx,
            _ => continue,
        };
        if module.struct_def_at(*struct_def_idx) == struct_def {
            let fn_handle = module.function_handle_at(fn_def.function);
            let fn_name = module.identifier_at(fn_handle.name);
            return Err(format!(
                "one-time witness type {}::{} is instantiated \
                         in the {}::{} function and must never be",
                module.self_id(),
                struct_name,
                module.self_id(),
                fn_name,
            ));
        }
    }
    Ok(())
}