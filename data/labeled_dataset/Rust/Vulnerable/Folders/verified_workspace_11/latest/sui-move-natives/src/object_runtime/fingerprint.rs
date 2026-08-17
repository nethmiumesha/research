use move_binary_format::errors::{PartialVMError, PartialVMResult};
use move_core_types::vm_status::StatusCode;
use move_vm_types::values::Value;
use sui_protocol_config::ProtocolConfig;
use sui_types::base_types::{MoveObjectType, ObjectID};
pub struct ObjectFingerprint(Option<ObjectFingerprint_>);
enum ObjectFingerprint_ {
    Empty,
    Preexisting {
        owner: ObjectID,
        ty: MoveObjectType,
        value: Value,
    },
}
impl ObjectFingerprint {
    #[cfg(debug_assertions)]
    pub fn is_disabled(&self) -> bool {
        self.0.is_none()
    }
    pub fn none(protocol_config: &ProtocolConfig) -> Self {
        if !protocol_config.minimize_child_object_mutations() {
            Self(None)
        } else {
            Self(Some(ObjectFingerprint_::Empty))
        }
    }
    pub fn preexisting(
        protocol_config: &ProtocolConfig,
        preexisting_owner: &ObjectID,
        preexisting_type: &MoveObjectType,
        preexisting_value: &Value,
    ) -> PartialVMResult<Self> {
        Ok(if !protocol_config.minimize_child_object_mutations() {
            Self(None)
        } else {
            Self(Some(ObjectFingerprint_::Preexisting {
                owner: *preexisting_owner,
                ty: preexisting_type.clone(),
                value: preexisting_value.copy_value()?,
            }))
        })
    }
    pub fn object_has_changed(
        &self,
        final_owner: &ObjectID,
        final_type: &MoveObjectType,
        final_value: &Option<Value>,
    ) -> PartialVMResult<bool> {
        use ObjectFingerprint_ as F;
        let Some(inner) = &self.0 else {
            return Err(
                PartialVMError::new(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR).with_message(
                    "Object fingerprint not enabled, yet we were asked for the changes".to_string(),
                ),
            );
        };
        Ok(match (inner, final_value) {
            (F::Empty, None) => false,
            (F::Empty, Some(_)) | (F::Preexisting { .. }, None) => true,
            (
                F::Preexisting {
                    owner: preexisting_owner,
                    ty: preexisting_type,
                    value: preexisting_value,
                },
                Some(final_value),
            ) => {
                !(preexisting_owner == final_owner
                    && preexisting_type == final_type
                    && preexisting_value.equals(final_value)?)
            }
        })
    }
}