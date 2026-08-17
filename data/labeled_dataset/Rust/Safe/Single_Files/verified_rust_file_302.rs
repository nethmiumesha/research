use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
#[derive(BorshDeserialize, BorshSerialize, PartialEq)]
pub enum RunningState {
    Running,
    Paused,
}