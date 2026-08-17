use move_core_types::account_address::AccountAddress;
use sui_types::{TypeTag, base_types::ObjectID, effects::AccumulatorOperation};
#[derive(Debug)]
pub enum MoveAccumulatorAction {
    Merge,
    Split,
}
impl MoveAccumulatorAction {
    pub fn into_sui_accumulator_action(self) -> AccumulatorOperation {
        match self {
            MoveAccumulatorAction::Merge => AccumulatorOperation::Merge,
            MoveAccumulatorAction::Split => AccumulatorOperation::Split,
        }
    }
}
#[derive(Debug)]
pub enum MoveAccumulatorValue {
    U64(u64),
    EventRef(u64),
}
#[derive(Debug)]
pub struct MoveAccumulatorEvent {
    pub accumulator_id: ObjectID,
    pub action: MoveAccumulatorAction,
    pub target_addr: AccountAddress,
    pub target_ty: TypeTag,
    pub value: MoveAccumulatorValue,
}