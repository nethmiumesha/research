use near_sdk::json_types::{U128, U64};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::AccountId;
#[derive(Serialize, Deserialize)]
#[serde(crate = "near_sdk::serde")]
pub struct Settings {
    pub deployer_id: AccountId,
    pub members: String,
    pub min_support: u32,
    pub min_duration: u32,
    pub max_duration: u32,
    pub min_bond: U128,
    pub unix_time: U64,
}