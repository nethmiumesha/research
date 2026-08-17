use crate::env::predecessor_account_id;
use crate::errors::throw_error;
use std::convert::TryInto;
use near_sdk::env::{current_account_id, is_valid_account_id, keccak256, signer_account_id};
use near_sdk::AccountId;
use near_sdk::PanicOnDefault;
use near_sdk::{collections::UnorderedMap, env, near_bindgen};
use crate::{AccountInfo, Community, CommunityContract, SecpPK, SecpPKInternal};
pub trait NFTFunc {
    fn set_default_nft_contract(&mut self, nft_contract: AccountId);
    fn get_default_nft_contract(&self) -> &Option<AccountId>;
}
#[cfg(not(target_arch = "wasm32"))]