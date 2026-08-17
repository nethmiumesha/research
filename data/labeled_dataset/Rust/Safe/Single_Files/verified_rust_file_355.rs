use near_plugins::{check_only, pause, FullAccessKeyFallback, Ownable, Pausable, Upgradable};
use std::convert::TryInto;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{env, near_bindgen, AccountId, PanicOnDefault};
#[near_bindgen]
#[derive(
    BorshDeserialize,
    BorshSerialize,
    PanicOnDefault,
    Ownable,
    Upgradable,
    FullAccessKeyFallback,
    Pausable,
)]
pub struct Counter {
    counter: u8,
}
#[near_bindgen]
impl Counter {
    #[init]
    pub fn new(owner: AccountId) -> Self {
        let mut res = Self { counter: 0 };
        res.set_owner(owner);
        res
    }
    pub fn get_counter(&self) -> u8 {
        self.counter
    }
    #[check_only(self, owner)]
    #[pause]
    pub fn increase_counter(&mut self) {
        self.counter += 1;
    }
    #[check_only(self, owner)]
    #[pause(allow_admin)]
    pub fn increase_counter2(&mut self) {
        self.counter += 1;
    }
    pub fn version(&self) -> String {
        "1.0.1".to_string()
    }
}