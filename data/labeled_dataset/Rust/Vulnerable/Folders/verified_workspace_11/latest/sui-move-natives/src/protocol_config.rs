use crate::get_extension;
use crate::object_runtime::ObjectRuntime;
use move_binary_format::errors::PartialVMResult;
use move_vm_runtime::native_functions::NativeContext;
use move_vm_types::{
    loaded_data::runtime_types::Type,
    natives::function::NativeResult,
    pop_arg,
    values::{Value, Vector},
};
use smallvec::smallvec;
use std::collections::VecDeque;
pub fn is_feature_enabled(
    context: &mut NativeContext,
    ty_args: Vec<Type>,
    mut args: VecDeque<Value>,
) -> PartialVMResult<NativeResult> {
    debug_assert!(ty_args.is_empty());
    debug_assert!(args.len() == 1);
    let feature_flag_name_bytes = pop_arg!(args, Vector);
    let bytes = feature_flag_name_bytes.to_vec_u8()?;
    let protocol_config = &get_extension!(context, ObjectRuntime)?.protocol_config;
    let is_enabled = match String::from_utf8(bytes.to_vec()) {
        Ok(s) => {
            match protocol_config.lookup_feature(s) {
                Some(value) => value,
                None => {
                    debug_assert!(false);
                    false
                }
            }
        }
        Err(_) => {
            debug_assert!(false);
            false
        }
    };
    Ok(NativeResult::ok(
        context.gas_used(),
        smallvec![Value::bool(is_enabled)],
    ))
}