mod account;
mod vesting;
mod types;
mod utils;
mod interfaces;
use std::collections::HashSet;
use near_sdk::{AccountId, near_bindgen, PanicOnDefault};
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{LookupMap, UnorderedMap, UnorderedSet};
use crate::account::VAccount;
use crate::types::VestingId;
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct OctVesting {
    pub accounts: LookupMap<AccountId, VAccount>,
    pub vesting: UnorderedMap<VestingId, Vesting>,
}