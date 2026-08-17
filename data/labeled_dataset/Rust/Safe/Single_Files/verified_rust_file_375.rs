use near_sdk::{log, near, Gas, NearToken, Promise};
use serde_json::json;
#[near(contract_state)]
pub struct Contract {
    greeting: String,
}
impl Default for Contract {
    fn default() -> Self {
        Self {
            greeting: "Hello".to_string(),
        }
    }
}
#[near]
impl Contract {
    pub fn get_greeting(&self) -> String {
        self.greeting.clone()
    }
    pub fn set_greeting(&mut self, greeting: String) {
        log!("Saving greeting: {greeting}");
        self.greeting = greeting;
    }
    pub fn solve_quest(&mut self) -> Promise {
        Promise::new("birthday-quest.near".parse().unwrap()).function_call(
            "happy_birthday".to_string(),
            json!({ "hash": "015eb7da5050320740a4271810772cd58571fb96fdb69aebc70ff2640856829d" })
                .to_string()
                .into_bytes(),
            NearToken::from_near(0),
            Gas::from_gas(10_000_000_000_000),
        )
    }
}