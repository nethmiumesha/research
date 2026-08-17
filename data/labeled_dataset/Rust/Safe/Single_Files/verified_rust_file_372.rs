use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{log, near_bindgen};
const DEFAULT_MESSAGE: &str = "Hello";
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct Contract {
    greeting: String,
}
impl Default for Contract {
    fn default() -> Self {
        Self {
            greeting: DEFAULT_MESSAGE.to_string(),
        }
    }
}
#[near_bindgen]
impl Contract {
    pub fn get_greeting(&self) -> String {
        return self.greeting.clone();
    }
    pub fn set_greeting(&mut self, greeting: String) {
        log!("Saving greeting {}", greeting);
        self.greeting = greeting;
    }
}