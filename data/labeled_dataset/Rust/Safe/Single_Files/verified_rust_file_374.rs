use hex;
use near_contract_standards::fungible_token::metadata::FungibleTokenMetadata;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{LookupMap, UnorderedMap, UnorderedSet};
use near_sdk::json_types::U128;
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{
    env, ext_contract, near_bindgen, AccountId, Balance, Gas,
    PanicOnDefault, Promise, PromiseResult,
};
use std::convert::TryFrom;
use crate::ft_callback::*;
use crate::internal::*;
use crate::utils::*;
use crate::view::*;
mod ft_callback;
mod internal;
mod utils;
mod view;
pub type AirdropId = u128;
#[derive(Deserialize, Serialize, BorshDeserialize, BorshSerialize, Clone, Debug)]
#[serde(crate = "near_sdk::serde")]
pub struct Proof {
    pub position: String,
    pub data: String,
}
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Contract {
    pub owner_id: AccountId,
    pub merkle_roots_by_id: LookupMap<AirdropId, String>,
    pub campaigns_by_account: LookupMap<AccountId, UnorderedSet<AirdropId>>,
    pub spent_list_by_campaign: UnorderedMap<AirdropId, UnorderedMap<AccountId, bool>>,
    pub ft_contract_by_campaign: LookupMap<AirdropId, String>,
}
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new(owner_id: AccountId) -> Self {
        Self {
            owner_id,
            merkle_roots_by_id: LookupMap::new(b"c"),
            campaigns_by_account: LookupMap::new(b"u"),
            spent_list_by_campaign: UnorderedMap::new(b"e"),
            ft_contract_by_campaign: LookupMap::new(b"h"),
        }
    }
    #[payable]
    pub fn create_airdrop(
        &mut self,
        merkle_root: String,
        ft_account_id: String,
        ft_balance: Balance,
    ) {
        let campaign_owner_id = env::predecessor_account_id();
        let airdrop_id = self.internal_add_campaign_to_account(&campaign_owner_id);
        self.merkle_roots_by_id.insert(&airdrop_id, &merkle_root);
        self.internal_add_ft_contract_to_campaign(&airdrop_id, &ft_account_id);
    }
    #[payable]
    pub fn claim(&mut self, airdrop_id: AirdropId, proof: Vec<Proof>, amount: Balance) {
        let user_id = env::predecessor_account_id();
        let is_issued = self.internal_check_issued_account(&airdrop_id, &user_id);
        assert_eq!(is_issued, false, "{} issued before!", user_id.clone());
        assert_eq!(
            self.internal_check_merkle_proof(&airdrop_id, &proof, amount),
            true,
            "Your proof is invalid"
        );
        self.internal_add_account_to_claimed_list(&airdrop_id);
    }
}