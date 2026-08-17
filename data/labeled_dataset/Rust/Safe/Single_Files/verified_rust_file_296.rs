use near_sdk::json_types::{Base58CryptoHash, Base64VecU8};
use near_sdk::near;
use crate::*;
#[near(serializers=[json])]
pub struct KeyInfo {
    pub balance: NearToken,
}
#[near(serializers=[json])]
pub struct LimitedAccessKey {
    pub public_key: PublicKey,
    pub allowance: NearToken,
    pub receiver_id: AccountId,
    pub method_names: String,
}
#[near(serializers=[json])]
pub struct CreateAccountOptions {
    pub full_access_keys: Option<Vec<PublicKey>>,
    pub limited_access_keys: Option<Vec<LimitedAccessKey>>,
    pub contract_bytes: Option<Vec<u8>>,
    pub contract_bytes_base64: Option<Base64VecU8>,
    pub use_global_contract_hash: Option<Base58CryptoHash>,
    pub use_global_contract_account_id: Option<AccountId>,
}