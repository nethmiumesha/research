use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{env, near_bindgen, BorshStorageKey, Gas, Promise, PromiseResult, log};
use near_sdk::collections::{LookupMap, UnorderedSet};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::AccountId;
use near_sdk::PanicOnDefault;
use near_sdk::json_types::{Base64VecU8};
mod metadata;
mod nft_666_token;
const GAS_FOR_FUNCTION_CALL: Gas = Gas(5_000_000_000_000);
const GAS_FOR_CALLBACK: Gas = Gas(5_000_000_000_000);
#[near_bindgen]
#[derive(Serialize, Deserialize, BorshDeserialize, BorshSerialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct AssetRights{
    ownership: AccountId,
    usage_rights: AccountId,
}
#[derive(PartialEq)]
enum Authority{
    From,
    Approved,
}
#[derive(BorshStorageKey, BorshSerialize)]
pub enum StorageRecord{
    Ownership,
    AssetsOwnInfo,
    AssetsUsageInfo,
    Tokens,
    Approvals,
    UsageApprovals,
    AssetsOwnTable{account_hash: Vec<u8>},
    AssetsUsageTable{account_hash: Vec<u8>},
    LeasingPeriod,
}
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Contract {
    owner_id: AccountId,
    total_supply: u64,
    contract_meta: metadata::ContractMetaData,
    owner_ship: LookupMap<String, AssetRights>,
    assets_own_info: LookupMap<AccountId, UnorderedSet<String>>,
    assets_usage_info: LookupMap<AccountId, UnorderedSet<String>>,
    tokens: LookupMap<String, metadata::TokenMetaData>,
    approvals: LookupMap<String, AccountId>,
    usage_approvals: LookupMap<String, AccountId>,
    leasing_period: LookupMap<String, u64>,
}
pub trait NFTBorrow{
    fn usageOf(&self, token_id: String)->AccountId;
}
pub trait NFTMetaData{
    fn name(&self) -> String;
    fn symbol(&self) -> String;
    fn tokenURI(&self, token_id: String) -> String;
}
pub trait NFTUsage{
    #[deny(useless_deprecated)]
    fn transferUsageFrom(&mut self, from: AccountId, to: AccountId, token_id: String);
    #[deny(useless_deprecated)]
    fn approveUsage(&mut self, approved: AccountId, token_id: String);
    #[deny(useless_deprecated)]
    fn getUsageApproved(&self, token_id: String) ->AccountId;
    fn transfer_usage_without_check(&mut self, from: AccountId, to: AccountId, token_id: String);
    fn lend_usage_to(&mut self, to: AccountId, token_id: String, period: u64);
    fn usage_return(&mut self, token_id: String);
    fn get_leasing_period(&self, token_id: String) -> u64;
}
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new(contract_meta: metadata::ContractMetaData) ->Self{
        Self{
            owner_id: env::predecessor_account_id(),
            total_supply: 0,
            contract_meta,
            owner_ship: LookupMap::new(StorageRecord::Ownership),
            assets_own_info: LookupMap::new(StorageRecord::AssetsOwnInfo),
            assets_usage_info: LookupMap::new(StorageRecord::AssetsUsageInfo),
            tokens: LookupMap::new(StorageRecord::Tokens),
            approvals: LookupMap::new(StorageRecord::Approvals),
            usage_approvals: LookupMap::new(StorageRecord::UsageApprovals),
            leasing_period: LookupMap::new(StorageRecord::LeasingPeriod),
        }
    }
    pub fn totalSupply(&self)-> u64{
        self.total_supply
    }
    pub fn balanceOf(&self, account_id: AccountId)-> u64{
        let v = self.assets_own_info.get(&account_id);
        if let Some(val) = v {
            val.len()
        }else{
            env::panic_str("None of the account!");
        }
    }
    pub fn ownerOf(&self, token_id: String)->AccountId{
        let v= self.owner_ship.get(&token_id);
        if let Some(val) = v {
            val.ownership
        }else{
            env::panic_str("The token_id dose not exist!");
        }
    }
    pub fn mint(&mut self, asset_rights: AssetRights, token_metadata: metadata::TokenMetaData) -> nft_666_token::NFT666Token{
        assert_eq!(env::predecessor_account_id(), self.owner_id, "Unauthorized");
        if !env::is_valid_account_id(asset_rights.ownership.as_bytes()){
            env::panic_str("invalid owner account!");
        }
        if !env::is_valid_account_id(asset_rights.usage_rights.as_bytes()){
            env::panic_str("invalid usage account!");
        }
        assert_eq!(asset_rights.ownership , asset_rights.usage_rights, "the `ownership` must be the same as `usage_rights` in `mint`");
        self.total_supply += 1;
        let token_id: String = token_metadata.to_hex_string();
        let token_id = token_id + env::current_account_id().as_str();
        let token_id = format!("{}+{}", token_id, self.total_supply);
        let token_id = hex::encode(env::sha256(token_id.as_bytes()));
        if self.tokens.contains_key(&token_id){
            env::panic_str("cannot create, check the metadata of the token!");
        }
        self.tokens.insert(&token_id, &token_metadata);
        self.owner_ship.insert(&token_id, &asset_rights);
        let mut owned_tokens = self.assets_own_info.get(&asset_rights.ownership).unwrap_or_else(||{
            UnorderedSet::new(StorageRecord::AssetsOwnTable {
                account_hash: env::sha256(asset_rights.ownership.as_bytes()),
            })
        });
        owned_tokens.insert(&token_id);
        self.assets_own_info.insert(&asset_rights.ownership, &owned_tokens);
        let mut usage_tokens = self.assets_usage_info.get(&asset_rights.usage_rights).unwrap_or_else(||{
            UnorderedSet::new(StorageRecord::AssetsUsageTable{
                account_hash: env::sha256(asset_rights.usage_rights.as_bytes()),
            })
        });
        usage_tokens.insert(&token_id);
        self.assets_usage_info.insert(&asset_rights.usage_rights, &usage_tokens);
        nft_666_token::NFT666Token{
            token_id,
            owner_id: asset_rights.ownership,
            usage_rights: asset_rights.usage_rights,
            metadata: Some(token_metadata),
        }
    }
    pub fn transferFrom(&mut self, from: AccountId, to: AccountId, token_id: String){
        if !env::is_valid_account_id(to.as_bytes()) {
            env::panic_str("Invalid `to` address!");
        }
        let art = self.owner_ship.get(&token_id).expect("`token_id` not exist!");
        assert_eq!(from, art.ownership, "Ownership Unauthorized");
        let pre_account = env::predecessor_account_id();
        if pre_account != from{
            if self.approvals.get(&token_id).expect("Caller Ownership Unauthorized: 1!") != pre_account{
                env::panic_str("Caller Ownership Unauthorized: 2");
            }
        }
        if !self.leasing_period.contains_key(&token_id){
            assert_eq!(art.ownership, art.usage_rights, "Usage Unauthorized: if there's no leasing, the `ownership` must be the same as `usage_rights`");
            self.transfer_usage_without_check(from.clone(), to.clone(), token_id.clone());
        }
        self.transfer_ownership_without_check(from, to, token_id);
    }
    pub fn safeTransferFrom(&mut self, from: AccountId, to: AccountId, token_id: String, data: String){
        self.transferFrom(from.clone(), to.clone(), token_id.clone());
        let arguments = near_sdk::serde_json::json!({
            "operator": env::predecessor_account_id(),
            "from": from.as_str(),
            "token_id": token_id,
            "data": data,
        });
        let arguments = Base64VecU8::from(arguments.to_string().into_bytes());
        Promise::new(to.clone())
        .function_call("onERC721Received".to_string(),
            arguments.into(),
            0,
            GAS_FOR_FUNCTION_CALL);
    }
    fn safeTransferFromNone(&mut self, from: AccountId, to: AccountId, token_id: String){
        self.safeTransferFrom(from, to, token_id, "".to_string());
    }
    pub fn approve(&mut self, approved: AccountId, token_id: String){
        let owner = self.owner_ship.get(&token_id).expect("Token does not exist!");
        assert_eq!(env::predecessor_account_id(), owner.ownership, "Ownership Unauthorized");
        self.approvals.insert(&token_id, &approved);
    }
    pub fn getApproved(&self, token_id: String) -> AccountId{
        self.approvals.get(&token_id).expect("token is not approved!")
    }
    pub fn setApprovalForAll(&mut self, operator: AccountId, approved: bool){
        let pre_account = env::predecessor_account_id();
        if pre_account == operator{
            return;
        }
        let assets_owned = self.assets_own_info.get(&pre_account).expect("None of assets!");
        if approved{
            for token in assets_owned.iter(){
                self.approvals.insert(&token, &operator);
            }
        }else{
            for token in assets_owned.iter(){
                self.approvals.remove(&token);
            }
        }
    }
    pub fn isApprovedForAll(&self, owner: AccountId, operator: AccountId) ->bool{
        let assets_owned = self.assets_own_info.get(&owner).expect("None of assets!");
        for token in assets_owned.iter(){
            let approved_opt = self.approvals.get(&token);
            if let Some(approved) = approved_opt {
                if approved != operator{
                    return false;
                }
            }else{
                return false;
            }
        }
        true
    }
    pub fn get_contract_meta_data(&self) -> metadata::ContractMetaData{
        self.contract_meta.clone()
    }
    #[private]
    fn transfer_ownership_without_check(&mut self, from: AccountId, to: AccountId, token_id: String){
        let mut art = self.owner_ship.get(&token_id).expect("token dose not exist!");
        let cur_owned_tokens = self.assets_own_info.get(&from);
        if let Some(mut cur_o_t) = cur_owned_tokens {
            cur_o_t.remove(&token_id);
            self.assets_own_info.insert(&from, &cur_o_t);
            let mut new_owned_tokens = self.assets_own_info.get(&to).unwrap_or_else(||{
                UnorderedSet::new(StorageRecord::AssetsOwnTable {
                    account_hash: env::sha256(to.as_bytes()),
                })
            });
            new_owned_tokens.insert(&token_id);
            self.assets_own_info.insert(&to, &new_owned_tokens);
            art.ownership = to;
            self.owner_ship.insert(&token_id, &art);
            self.approvals.remove(&token_id);
        }else{
            env::panic_str("There's a bug, because someone has the ownership, but the asset dose not existed in the asset_own_info table!");
        }
    }
}
#[near_bindgen]
impl NFTUsage for Contract{
    #[private]
    #[deny(useless_deprecated)]
    fn transferUsageFrom(&mut self, from: AccountId, to: AccountId, token_id: String){
        if !env::is_valid_account_id(to.as_bytes()){
            env::panic_str("Invalid usage account id!");
        }
        let mut asset_right = self.owner_ship.get(&token_id).expect("token dose not exist!");
        assert_eq!(from, asset_right.usage_rights, "Unauthorized");
        let pre_account = env::predecessor_account_id();
        if pre_account != from{
            if self.usage_approvals.get(&token_id).expect("") != pre_account{
                env::panic_str("Caller Unauthorized");
            }
        }
        self.transfer_usage_without_check(from, to, token_id);
    }
    #[private]
    #[deny(useless_deprecated)]
    fn approveUsage(&mut self, approved: AccountId, token_id: String){
        let owner = self.owner_ship.get(&token_id).expect("token does not exist!");
        assert_eq!(env::predecessor_account_id(), owner.usage_rights, "Usage Unauthorized");
        self.usage_approvals.insert(&token_id, &approved);
    }
    #[private]
    #[deny(useless_deprecated)]
    fn getUsageApproved(&self, token_id: String) ->AccountId{
        self.usage_approvals.get(&token_id).expect("token does not exist!")
    }
    #[private]
    fn transfer_usage_without_check(&mut self, from: AccountId, to: AccountId, token_id: String){
        let mut asset_right = self.owner_ship.get(&token_id).expect("token dose not exist!");
        let mut cur_usage_tokens = self.assets_usage_info.get(&from).expect("There's a bug, because someone has the usage_right, but the asset does not existed in the asset_usage_info table!");
        cur_usage_tokens.remove(&token_id);
        self.assets_usage_info.insert(&from, &cur_usage_tokens);
        let mut new_usage_tokens = self.assets_usage_info.get(&to).unwrap_or_else(||{
            UnorderedSet::new(StorageRecord::AssetsUsageTable{
                account_hash: env::sha256(to.as_bytes()),
            })
        });
        new_usage_tokens.insert(&token_id);
        self.assets_usage_info.insert(&to, &new_usage_tokens);
        asset_right.usage_rights = to;
        self.owner_ship.insert(&token_id, &asset_right);
        self.usage_approvals.remove(&token_id);
    }
    fn lend_usage_to(&mut self, to: AccountId, token_id: String, period: u64){
        if !env::is_valid_account_id(to.as_bytes()){
            env::panic_str("Invalid `to` account!");
        }
        let pre_account = env::predecessor_account_id();
        let mut art = self.owner_ship.get(&token_id).expect("token does not exist!");
        if !((art.ownership == pre_account) && (art.usage_rights == pre_account))
        {
            env::panic_str("Lend Unauthorized!");
        }
        let mut cur_usage_tokens = self.assets_usage_info.get(&art.usage_rights).expect("There's a bug, because someone has the usage_right, but the asset does not existed in the asset_usage_info table!");
        cur_usage_tokens.remove(&token_id);
        self.assets_usage_info.insert(&art.usage_rights, &cur_usage_tokens);
        let mut new_usage_tokens = self.assets_usage_info.get(&to).unwrap_or_else(||{
            UnorderedSet::new(StorageRecord::AssetsUsageTable{
                account_hash: env::sha256(to.as_bytes()),
            })
        });
        new_usage_tokens.insert(&token_id);
        self.assets_usage_info.insert(&to, &new_usage_tokens);
        art.usage_rights = to;
        self.owner_ship.insert(&token_id, &art);
        self.usage_approvals.remove(&token_id);
        self.leasing_period.insert(&token_id, &(env::block_height() + period));
    }
    fn usage_return(&mut self, token_id: String){
        let pre_account = env::predecessor_account_id();
        let mut art = self.owner_ship.get(&token_id).expect("token does not exist!");
        if pre_account != art.usage_rights{
            if pre_account != art.ownership{
                env::panic_str("Return Unauthorized!");
            }else{
                let token_lease_period = self.leasing_period.get(&token_id).expect("No leasing record!");
                if env::block_height() <= token_lease_period{
                    env::panic_str("Return Unauthorized. Not time up!");
                }
            }
        }
        let mut cur_usage_tokens = self.assets_usage_info.get(&art.usage_rights).expect("There's a bug, because someone has the usage_right, but the asset does not existed in the asset_usage_info table!");
        cur_usage_tokens.remove(&token_id);
        self.assets_usage_info.insert(&art.usage_rights, &cur_usage_tokens);
        let mut new_usage_tokens = self.assets_usage_info.get(&art.ownership).unwrap_or_else(||{
            UnorderedSet::new(StorageRecord::AssetsUsageTable{
                account_hash: env::sha256(art.ownership.as_bytes()),
            })
        });
        new_usage_tokens.insert(&token_id);
        self.assets_usage_info.insert(&art.ownership, &new_usage_tokens);
        art.usage_rights = art.ownership.clone();
        self.owner_ship.insert(&token_id, &art);
        self.usage_approvals.remove(&token_id);
        self.leasing_period.remove(&token_id);
    }
    fn get_leasing_period(&self, token_id: String)->u64{
        self.leasing_period.get(&token_id).expect("token is not lent")
    }
}
#[near_bindgen]
impl NFTBorrow for Contract{
    fn usageOf(&self, token_id: String)->AccountId{
        let v= self.owner_ship.get(&token_id);
        if let Some(val) = v {
            val.usage_rights
        }else{
            env::panic_str("The token_id dose not exist!");
        }
    }
}
#[near_bindgen]
impl NFTMetaData for Contract{
    fn name(&self) ->String{
        self.contract_meta.name.clone()
    }
    fn symbol(&self) ->String{
        self.contract_meta.symbol.clone()
    }
    fn tokenURI(&self, token_id: String)->String{
        let v = self.tokens.get(&token_id);
        if let Some(token_meta) = v {
            if let Some(media_uri) = token_meta.media {
                media_uri
            }else{
                "".to_string()
            }
        }else{
            env::panic_str("None of the token_id");
        }
    }
}