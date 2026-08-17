use near_sdk::borsh::{ self, BorshDeserialize, BorshSerialize };
use near_sdk::json_types::{ U128 };
use near_sdk::{
    env,
    ext_contract,
    near_bindgen,
    AccountId,
    PanicOnDefault,
    Promise,
    PromiseOrValue,
    CryptoHash,
    BorshStorageKey,
    assert_self,
};
use near_sdk::collections::{ LookupMap, TreeMap, UnorderedSet, UnorderedMap };
use mfight_sdk::market::base::MarketFeature;
use mfight_sdk::market::{  TokenId, ContractAndTokenId };
use mfight_sdk::metadata::FungibleTokenId;
use mfight_sdk::reputation::ReputationFeature;
mod ft_callbacks;
mod nft_callbacks;
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Contract {
    pub owner_id: AccountId,
    pub market: MarketFeature,
}
#[derive(BorshStorageKey, BorshSerialize)]
pub enum StorageKey {
    Sales,
    ByOwnerId,
    ByNFTContractId,
    FTTokenIds,
    StorageDeposits,
    Reputation,
}
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new_with_default_meta(owner_id: AccountId) -> Self {
        Self::new(owner_id)
    }
    #[init]
    pub fn new(owner_id: AccountId) -> Self {
        let this = Self {
            owner_id: owner_id.clone().into(),
            market: MarketFeature::new(
                owner_id.clone(),
                None,
                None,
                StorageKey::Sales,
                StorageKey::ByOwnerId,
                StorageKey::ByNFTContractId,
                StorageKey::FTTokenIds,
                StorageKey::StorageDeposits,
                Some(StorageKey::Reputation),
            ),
        };
        this
    }
    #[init(ignore_state)]
    #[private]
    pub fn migrate() -> Self {
        #[derive(BorshDeserialize, BorshSerialize)]
        struct OldMarket {
            owner_id: AccountId,
			sales: UnorderedMap<ContractAndTokenId, Sale>,
			by_owner_id: TreeMap<AccountId, UnorderedSet<ContractAndTokenId>>,
			by_nft_contract_id: LookupMap<AccountId, UnorderedSet<TokenId>>,
			ft_token_ids: UnorderedSet<AccountId>,
			storage_deposits: LookupMap<AccountId, Balance>,
			bid_history_length: u8,
            reputation: Option<ReputationFeature>,
        }
        #[derive(BorshDeserialize)]
        struct Old {
            owner_id: AccountId,
            market: OldMarket,
        }
        let old: Old = env::state_read().expect("Error");
        let market = MarketFeature {
            owner_id: old.market.owner_id,
		    sales: old.market.sales,
		    by_owner_id: old.market.by_owner_id,
		    by_nft_contract_id: old.market.by_nft_contract_id,
		    ft_token_ids: old.market.ft_token_ids,
		    storage_deposits: old.market.storage_deposits,
		    bid_history_length: old.market.bid_history_length,
		    reputation: old.market.reputation,
        };
        Self {
            owner_id: old.owner_id,
            market: market,
        }
    }
}
mfight_sdk::impl_market_core!(Contract, market);
mfight_sdk::impl_market_enumeration!(Contract, market);
mfight_sdk::impl_reputation_feature!(Contract, market, reputation);