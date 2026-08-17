use near_sdk::Timestamp;
use std::cmp::min;
use std::collections::HashMap;
use std::convert::TryFrom;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::{LazyOption, LookupMap, UnorderedMap, UnorderedSet};
use near_sdk::json_types::{Base64VecU8, ValidAccountId, U128, U64};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{
    env, log, near_bindgen, AccountId, Balance, CryptoHash, PanicOnDefault, Promise, StorageUsage,
};
pub use crate::enumerable::*;
use crate::internal::*;
pub use crate::metadata::*;
pub use crate::mint::*;
pub use crate::nft_core::*;
pub use crate::token::*;
mod enumerable;
mod internal;
mod metadata;
mod mint;
mod nft_core;
mod token;
const DATA_IMAGE_SVG_NEAR_ICON: &str = "data:image/svg+xml,%3Csvg xmlns='http:
const MINT_FEE: Balance = 2_000_000_000_000_000_000_000_0;
near_sdk::setup_alloc!();
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Contract {
    pub tokens_per_owner: LookupMap<AccountId, UnorderedSet<TokenId>>,
    pub tokens_by_id: LookupMap<TokenId, Token>,
    pub token_metadata_by_id: UnorderedMap<TokenId, TokenMetadata>,
    pub owner_id: AccountId,
    pub extra_storage_in_bytes_per_token: StorageUsage,
    pub metadata: LazyOption<NFTMetadata>,
    pub area_metadata_by_id: UnorderedMap<String, AreaMetadata>,
}
#[derive(BorshSerialize)]
pub enum StorageKey {
    TokensPerOwner,
    TokenPerOwnerInner { account_id_hash: CryptoHash },
    TokensById,
    TokenMetadataById,
    AreaMetadataById,
    NftMetadata,
    TokensPerType,
    TokensPerTypeInner { token_type_hash: CryptoHash },
    TokenTypesLocked,
}
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new_default_meta(owner_id: ValidAccountId) -> Self {
        Self::new(
            owner_id,
            NFTMetadata {
                spec: "nft-1.0.0".to_string(),
                name: "The metaverse".to_string(),
                symbol: "Land".to_string(),
                icon: Some(DATA_IMAGE_SVG_NEAR_ICON.to_string()),
                base_uri: None,
                reference: None,
                reference_hash: None,
            },
        )
    }
    #[init]
    pub fn new(owner_id: ValidAccountId, metadata: NFTMetadata) -> Self {
        let mut this = Self {
            tokens_per_owner: LookupMap::new(StorageKey::TokensPerOwner.try_to_vec().unwrap()),
            tokens_by_id: LookupMap::new(StorageKey::TokensById.try_to_vec().unwrap()),
            token_metadata_by_id: UnorderedMap::new(
                StorageKey::TokenMetadataById.try_to_vec().unwrap(),
            ),
            owner_id: owner_id.into(),
            extra_storage_in_bytes_per_token: 0,
            metadata: LazyOption::new(
                StorageKey::NftMetadata.try_to_vec().unwrap(),
                Some(&metadata),
            ),
            area_metadata_by_id: UnorderedMap::new(
                StorageKey::AreaMetadataById.try_to_vec().unwrap(),
            ),
        };
        this.measure_min_token_storage_cost();
        this
    }
    fn measure_min_token_storage_cost(&mut self) {
        let initial_storage_usage = env::storage_usage();
        let tmp_account_id = "a".repeat(64);
        let u = UnorderedSet::new(
            StorageKey::TokenPerOwnerInner {
                account_id_hash: hash_account_id(&tmp_account_id),
            }
            .try_to_vec()
            .unwrap(),
        );
        self.tokens_per_owner.insert(&tmp_account_id, &u);
        let tokens_per_owner_entry_in_bytes = env::storage_usage() - initial_storage_usage;
        let owner_id_extra_cost_in_bytes = (tmp_account_id.len() - self.owner_id.len()) as u64;
        self.extra_storage_in_bytes_per_token =
            tokens_per_owner_entry_in_bytes + owner_id_extra_cost_in_bytes;
        self.tokens_per_owner.remove(&tmp_account_id);
    }
    pub fn get_area(&self, name: String) -> Option<AreaMetadata> {
        let hash = hex::encode(&env::sha256(name.as_bytes()));
        self.area_metadata_by_id.get(&hash)
    }
    pub fn open_area(
        &mut self,
        name: String,
        limit: u64,
        price: String,
        open_time: Timestamp,
        close_time: Timestamp,
    ) {
        assert!(
            env::predecessor_account_id() == self.owner_id,
            "Caller is not owner."
        );
        let hash = hex::encode(&env::sha256(name.as_bytes()));
        self.area_metadata_by_id.insert(
            &hash.clone(),
            &AreaMetadata {
                name: name,
                limit: limit,
                land_sold: 0u64,
                land_price: price.parse().unwrap(),
                open_time: open_time,
                close_time: close_time,
            },
        );
    }
    #[payable]
    pub fn buy_land(&mut self, name: String) {
        let area_data = self.get_area(name.clone());
        assert!(area_data != None, "Area no exist.");
        let mut area = area_data.unwrap();
        assert!(
            env::block_timestamp() > area.open_time,
            "This area has not started selling lands yet"
        );
        log!(
            "{}",
            format!(
                "close time: {}, time block: {}",
                area.close_time,
                env::block_timestamp()
            )
        );
        assert!(
            env::attached_deposit() >= area.land_price + MINT_FEE,
            "Please deposit price equal land price + mint fee, excess mint fee will be refund !"
        );
        let new_name = name.clone() + "#" + &area.land_sold.to_string();
        let token_id = hex::encode(&env::sha256(new_name.as_bytes()));
        let area_hash = hex::encode(&env::sha256(name.as_bytes()));
        area.land_sold += 1;
        self.area_metadata_by_id.insert(&area_hash, &area);
        let token: TokenMetadata = TokenMetadata {
            title: Some(String::from(new_name.clone())),
            description: Some(String::from(new_name)),
            media: Some(String::from("https:
            media_hash: None,
            copies: Some(1),
            issued_at: Some(env::block_timestamp()),
            city: Some(name),
            location: Some(String::from("10, 20")),
            rare: Some(String::from("R")),
            mining_efficiency: Some(1),
            mining_power: Some(10),
        };
        self.nft_mint(
            Some(token_id),
            token,
            Some(HashMap::new()),
            Some(ValidAccountId::try_from(env::predecessor_account_id()).unwrap()),
            area.land_price,
        )
    }
    pub fn get_land(&self, name: String) -> Option<TokenMetadata> {
        let hash = hex::encode(&env::sha256(name.as_bytes()));
        self.token_metadata_by_id.get(&hash)
    }
    pub fn get_lands_by_owner(&self, owner_id: AccountId) -> Vec<TokenMetadata> {
        let token_ids = self
            .tokens_per_owner
            .get(&owner_id)
            .unwrap_or_else(|| UnorderedSet::new(b"".to_vec()));
        token_ids
            .iter()
            .map(|token_id| self.token_metadata_by_id.get(&token_id).unwrap())
            .collect()
    }
    pub fn get_all_areas(&self) -> Vec<AreaMetadata> {
        self.area_metadata_by_id.values().collect()
    }
}