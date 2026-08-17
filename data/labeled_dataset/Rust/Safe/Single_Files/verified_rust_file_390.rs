use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::store::{LookupMap, IterableMap, IterableSet, Vector};
use near_sdk::json_types::U128;
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{
    env, near_bindgen, require, AccountId, BorshStorageKey, NearToken,
    PanicOnDefault, Promise, PromiseOrValue,
};
use near_sdk::serde_json::json;
use std::collections::HashMap;
pub use near_contract_standards::non_fungible_token::core::{
    NonFungibleTokenCore, NonFungibleTokenResolver,
};
pub use near_contract_standards::non_fungible_token::enumeration::NonFungibleTokenEnumeration;
pub use near_contract_standards::non_fungible_token::metadata::{
    NFTContractMetadata, NonFungibleTokenMetadataProvider, TokenMetadata, NFT_METADATA_SPEC,
};
pub use near_contract_standards::non_fungible_token::{Token, TokenId};
use near_contract_standards::non_fungible_token::NonFungibleToken;
const DATA_IMAGE_SVG_ETRAP_ICON: &str = "data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20100%22%3E%3Ccircle%20cx%3D%2250%22%20cy%3D%2250%22%20r%3D%2240%22%20fill%3D%22%234A90E2%22%2F%3E%3Ctext%20x%3D%2250%22%20y%3D%2260%22%20text-anchor%3D%22middle%22%20fill%3D%22white%22%20font-size%3D%2230%22%20font-weight%3D%22bold%22%3EETRAP%3C%2Ftext%3E%3C%2Fsvg%3E";
const RECENT_TOKENS_LIMIT: u64 = 100;
const YOCTO_PER_NEAR: u128 = 1_000_000_000_000_000_000_000_000;
#[derive(BorshSerialize, BorshStorageKey)]
enum StorageKey {
    NonFungibleToken,
    TokenMetadata,
    Enumeration,
    Approval,
    BatchSummaries,
    TokensByDatabase,
    TokensByDatabaseInner { database_hash: Vec<u8> },
    TokensByMonth,
    TokensByMonthInner { month_hash: Vec<u8> },
    TokensByTimestamp,
    RecentTokens,
    TokensByTable,
    TokensByTableInner { table_hash: Vec<u8> },
    TotalBatchesPerDatabase,
    DatabaseList,
}
#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct BatchSummary {
    pub database_name: String,
    pub table_names: Vec<String>,
    pub timestamp: u64,
    pub tx_count: u32,
    pub merkle_root: String,
    pub s3_bucket: String,
    pub s3_key: String,
    pub size_bytes: u64,
    pub operation_counts: OperationCounts,
}
#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct OperationCounts {
    pub inserts: u32,
    pub updates: u32,
    pub deletes: u32,
}
#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct MerkleTreeBatchSummary {
    pub merkle_root: String,
    pub leaf_count: u32,
    pub hash_algorithm: String,
    pub batch_id: String,
    pub organization_id: String,
    pub database_name: String,
    pub batch_summary: BatchSummaryInfo,
    pub s3_bucket: String,
    pub s3_prefix: String,
    pub anchoring_data: AnchoringData,
}
#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct BatchSummaryInfo {
    pub start_timestamp: u64,
    pub end_timestamp: u64,
    pub total_transactions: u32,
    pub operations_summary: OperationsSummary,
}
#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct OperationsSummary {
    pub inserts: u32,
    pub updates: u32,
    pub deletes: u32,
}
#[derive(BorshDeserialize, BorshSerialize, Serialize, Deserialize, Clone)]
#[serde(crate = "near_sdk::serde")]
pub struct AnchoringData {
    pub block_height: u64,
    pub tx_hash: String,
    pub gas_used: String,
    pub etrap_fee: String,
}
#[derive(BorshDeserialize, BorshSerialize)]
pub struct ETRAPSettings {
    pub fee_amount: NearToken,
    pub etrap_treasury: AccountId,
    pub paused: bool,
}
#[derive(Serialize, Deserialize)]
#[serde(crate = "near_sdk::serde")]
pub struct BatchInfo {
    pub token_id: TokenId,
    pub owner_id: AccountId,
    pub metadata: TokenMetadata,
    pub batch_summary: BatchSummary,
}
#[derive(Serialize, Deserialize)]
#[serde(crate = "near_sdk::serde")]
pub struct BatchSearchResult {
    pub batches: Vec<BatchInfo>,
    pub total_count: u64,
    pub has_more: bool,
}
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct ETRAPContract {
    tokens: NonFungibleToken,
    metadata: NFTContractMetadata,
    batch_summaries: LookupMap<TokenId, BatchSummary>,
    tokens_by_database: LookupMap<String, IterableSet<TokenId>>,
    tokens_by_month: LookupMap<String, Vector<TokenId>>,
    tokens_by_timestamp: IterableMap<u64, TokenId>,
    recent_tokens: Vector<TokenId>,
    tokens_by_table: LookupMap<String, IterableSet<TokenId>>,
    total_batches_per_database: LookupMap<String, u64>,
    database_list: IterableSet<String>,
    etrap_settings: ETRAPSettings,
}
impl ETRAPContract {
    fn timestamp_to_year_month(timestamp: u64) -> String {
        let seconds = timestamp / 1000;
        let days = seconds / 86400;
        let years = 1970 + (days / 365);
        let month = ((days % 365) / 30) + 1;
        format!("{:04}-{:02}", years, month)
    }
    fn get_batch_info(&self, token_id: &TokenId) -> BatchInfo {
        let token = self.tokens.nft_token(token_id.clone()).expect("Token not found");
        let batch_summary = self.batch_summaries.get(token_id).expect("Batch summary not found");
        BatchInfo {
            token_id: token_id.clone(),
            owner_id: token.owner_id,
            metadata: token.metadata.unwrap_or_else(|| TokenMetadata {
                title: Some("ETRAP Batch".to_string()),
                description: None,
                media: None,
                media_hash: None,
                copies: Some(1),
                issued_at: None,
                expires_at: None,
                starts_at: None,
                updated_at: None,
                extra: None,
                reference: None,
                reference_hash: None,
            }),
            batch_summary: batch_summary.clone(),
        }
    }
    fn normalize_hash(hash: &str) -> String {
        if hash.starts_with("0x") {
            hash[2..].to_string()
        } else {
            hash.to_string()
        }
    }
    fn bytes_to_hex(bytes: &[u8]) -> String {
        bytes.iter()
            .map(|b| format!("{:02x}", b))
            .collect::<String>()
    }
    fn internal_mint_with_indices(
        &mut self,
        token_id: TokenId,
        receiver_id: AccountId,
        token_metadata: TokenMetadata,
        batch_summary: BatchSummary,
    ) -> Token {
        let database = batch_summary.database_name.clone();
        let timestamp = batch_summary.timestamp;
        let year_month = Self::timestamp_to_year_month(timestamp);
        let token = self.tokens.internal_mint_with_refund(
            token_id.clone(),
            receiver_id.clone(),
            Some(token_metadata),
            None,
        );
        let mut db_tokens = self.tokens_by_database.remove(&database)
            .unwrap_or_else(|| IterableSet::new(
                StorageKey::TokensByDatabaseInner {
                    database_hash: env::sha256(database.as_bytes())
                }
            ));
        db_tokens.insert(token_id.clone());
        self.tokens_by_database.insert(database.clone(), db_tokens);
        let mut month_tokens = self.tokens_by_month.remove(&year_month)
            .unwrap_or_else(|| Vector::new(
                StorageKey::TokensByMonthInner {
                    month_hash: env::sha256(year_month.as_bytes())
                }
            ));
        month_tokens.push(token_id.clone());
        self.tokens_by_month.insert(year_month.clone(), month_tokens);
        self.tokens_by_timestamp.insert(timestamp, token_id.clone());
        for table in &batch_summary.table_names {
            let mut table_tokens = self.tokens_by_table.remove(table)
                .unwrap_or_else(|| IterableSet::new(
                    StorageKey::TokensByTableInner {
                        table_hash: env::sha256(table.as_bytes())
                    }
                ));
            table_tokens.insert(token_id.clone());
            self.tokens_by_table.insert(table.clone(), table_tokens);
        }
        self.recent_tokens.push(token_id.clone());
        if self.recent_tokens.len() > RECENT_TOKENS_LIMIT as u32 {
            let mut new_recent = Vector::new(StorageKey::RecentTokens);
            for i in 1..self.recent_tokens.len() {
                new_recent.push(self.recent_tokens.get(i).unwrap().clone());
            }
            self.recent_tokens = new_recent;
        }
        self.batch_summaries.insert(token_id.clone(), batch_summary);
        let count = self.total_batches_per_database.get(&database).copied().unwrap_or(0) + 1;
        self.total_batches_per_database.insert(database.clone(), count);
        self.database_list.insert(database);
        token
    }
}
#[near_bindgen]
impl ETRAPContract {
    #[init]
    pub fn new(
        organization_id: AccountId,
        organization_name: String,
        etrap_treasury: AccountId,
        etrap_fee_amount: f64,
    ) -> Self {
        require!(!env::state_exists(), "Already initialized");
        require!(etrap_fee_amount >= 0.0, "Fee amount must be non-negative");
        let fee_amount_yocto = (etrap_fee_amount * YOCTO_PER_NEAR as f64) as u128;
        let metadata = NFTContractMetadata {
            spec: NFT_METADATA_SPEC.to_string(),
            name: format!("ETRAP Document Integrity Certificates - {}", organization_name),
            symbol: format!("ETRAP-{}", organization_name.chars().take(4).collect::<String>().to_uppercase()),
            icon: Some(DATA_IMAGE_SVG_ETRAP_ICON.to_string()),
            base_uri: None,
            reference: Some("https:
            reference_hash: None,
        };
        Self {
            tokens: NonFungibleToken::new(
                StorageKey::NonFungibleToken,
                organization_id.clone(),
                Some(StorageKey::TokenMetadata),
                Some(StorageKey::Enumeration),
                Some(StorageKey::Approval),
            ),
            metadata,
            batch_summaries: LookupMap::new(StorageKey::BatchSummaries),
            tokens_by_database: LookupMap::new(StorageKey::TokensByDatabase),
            tokens_by_month: LookupMap::new(StorageKey::TokensByMonth),
            tokens_by_timestamp: IterableMap::new(StorageKey::TokensByTimestamp),
            recent_tokens: Vector::new(StorageKey::RecentTokens),
            tokens_by_table: LookupMap::new(StorageKey::TokensByTable),
            total_batches_per_database: LookupMap::new(StorageKey::TotalBatchesPerDatabase),
            database_list: IterableSet::new(StorageKey::DatabaseList),
            etrap_settings: ETRAPSettings {
                fee_amount: NearToken::from_yoctonear(fee_amount_yocto),
                etrap_treasury,
                paused: false,
            },
        }
    }
    #[payable]
    pub fn mint_batch(
        &mut self,
        token_id: TokenId,
        receiver_id: AccountId,
        token_metadata: TokenMetadata,
        batch_summary: BatchSummary,
    ) -> Token {
        require!(!self.etrap_settings.paused, "Contract is paused");
        require!(
            self.tokens.nft_token(token_id.clone()).is_none(),
            "Token already exists"
        );
        let attached_deposit = env::attached_deposit();
        let storage_deposit = NearToken::from_yoctonear(env::storage_byte_cost().as_yoctonear() * 4000);
        let etrap_fee = self.etrap_settings.fee_amount;
        let total_required = storage_deposit.saturating_add(etrap_fee);
        require!(
            attached_deposit >= total_required,
            format!("Insufficient deposit. Required: {} yoctoNEAR (storage: {}, fee: {})",
                total_required.as_yoctonear(),
                storage_deposit.as_yoctonear(),
                etrap_fee.as_yoctonear())
        );
        if etrap_fee > NearToken::from_yoctonear(0) {
            Promise::new(self.etrap_settings.etrap_treasury.clone())
                .transfer(etrap_fee);
        }
        let token = self.internal_mint_with_indices(
            token_id.clone(),
            receiver_id.clone(),
            token_metadata.clone(),
            batch_summary.clone(),
        );
        let event_data = json!({
            "standard": "nep171",
            "version": "1.0.0",
            "event": "nft_mint",
            "data": [{
                "owner_id": receiver_id.to_string(),
                "token_ids": [token_id.clone()],
                "batch_summary": {
                    "database": batch_summary.database_name,
                    "timestamp": batch_summary.timestamp,
                    "merkle_root": batch_summary.merkle_root,
                    "tx_count": batch_summary.tx_count,
                    "tables": batch_summary.table_names,
                    "s3_location": {
                        "bucket": batch_summary.s3_bucket,
                        "key": batch_summary.s3_key
                    }
                },
                "fee_info": {
                    "etrap_fee": etrap_fee.as_yoctonear().to_string(),
                    "treasury": self.etrap_settings.etrap_treasury.to_string()
                }
            }]
        });
        env::log_str(&format!("EVENT_JSON:{}", event_data));
        token
    }
    pub fn verify_document_in_batch(
        &self,
        token_id: TokenId,
        document_hash: String,
        merkle_proof: Vec<String>,
        leaf_index: u32,
    ) -> bool {
        let batch_summary = match self.batch_summaries.get(&token_id) {
            Some(summary) => summary,
            None => {
                env::log_str(&format!("Batch not found: {}", token_id));
                return false;
            }
        };
        if batch_summary.merkle_root.starts_with("simple_concat:") {
            let expected_root = &batch_summary.merkle_root[14..];
            let mut current_hash = document_hash;
            let mut current_index = leaf_index;
            for proof_element in merkle_proof {
                if current_index % 2 == 0 {
                    current_hash = format!("{}{}", current_hash, proof_element);
                } else {
                    current_hash = format!("{}{}", proof_element, current_hash);
                }
                current_index /= 2;
            }
            return current_hash == expected_root;
        }
        let use_sha256 = batch_summary.merkle_root.len() == 64 &&
                        batch_summary.merkle_root.chars().all(|c| c.is_ascii_hexdigit());
        if use_sha256 {
            let mut current_hash = Self::normalize_hash(&document_hash);
            let mut current_index = leaf_index;
            if current_hash.len() != 64 {
                let hash_bytes = env::sha256(current_hash.as_bytes());
                current_hash = Self::bytes_to_hex(&hash_bytes);
            }
            for proof_element in merkle_proof.iter() {
                let sibling_hash = Self::normalize_hash(proof_element);
                let combined = if current_index % 2 == 0 {
                    format!("{}{}", current_hash, sibling_hash)
                } else {
                    format!("{}{}", sibling_hash, current_hash)
                };
                let hash_bytes = env::sha256(combined.as_bytes());
                current_hash = Self::bytes_to_hex(&hash_bytes);
                current_index /= 2;
            }
            let is_valid = current_hash == Self::normalize_hash(&batch_summary.merkle_root);
            env::log_str(&format!(
                "SHA256 verification - Expected: {}, Got: {}, Valid: {}",
                batch_summary.merkle_root, current_hash, is_valid
            ));
            is_valid
        } else {
            let mut current_hash = document_hash;
            let mut current_index = leaf_index;
            for proof_element in merkle_proof {
                if current_index % 2 == 0 {
                    current_hash = format!("{}{}", current_hash, proof_element);
                } else {
                    current_hash = format!("{}{}", proof_element, current_hash);
                }
                current_index /= 2;
            }
            let is_valid = current_hash == batch_summary.merkle_root;
            env::log_str(&format!(
                "Simple verification - Expected: {}, Got: {}, Valid: {}",
                batch_summary.merkle_root, current_hash, is_valid
            ));
            is_valid
        }
    }
    pub fn compute_merkle_root(&self, transaction_hashes: Vec<String>, use_sha256: bool) -> String {
        if transaction_hashes.is_empty() {
            return String::new();
        }
        let mut current_level: Vec<String> = if use_sha256 {
            transaction_hashes.iter()
                .map(|tx| {
                    let normalized = Self::normalize_hash(tx);
                    if normalized.len() == 64 && normalized.chars().all(|c| c.is_ascii_hexdigit()) {
                        normalized
                    } else {
                        let hash_bytes = env::sha256(tx.as_bytes());
                        Self::bytes_to_hex(&hash_bytes)
                    }
                })
                .collect()
        } else {
            transaction_hashes
        };
        while current_level.len() > 1 {
            let mut next_level = Vec::new();
            for i in (0..current_level.len()).step_by(2) {
                if i + 1 < current_level.len() {
                    let combined = if use_sha256 {
                        let concat = format!("{}{}", current_level[i], current_level[i + 1]);
                        let hash_bytes = env::sha256(concat.as_bytes());
                        Self::bytes_to_hex(&hash_bytes)
                    } else {
                        format!("{}{}", current_level[i], current_level[i + 1])
                    };
                    next_level.push(combined);
                } else {
                    next_level.push(current_level[i].clone());
                }
            }
            current_level = next_level;
        }
        current_level[0].clone()
    }
    pub fn generate_merkle_proof(&self, transactions: Vec<String>, tx_index: u32, use_sha256: bool) -> Vec<String> {
        if transactions.is_empty() || tx_index >= transactions.len() as u32 {
            return vec![];
        }
        let mut tree: Vec<Vec<String>> = vec![];
        let mut current_level: Vec<String> = if use_sha256 {
            transactions.iter()
                .map(|tx| {
                    let hash_bytes = env::sha256(tx.as_bytes());
                    Self::bytes_to_hex(&hash_bytes)
                })
                .collect()
        } else {
            transactions
        };
        tree.push(current_level.clone());
        while current_level.len() > 1 {
            let mut next_level = Vec::new();
            for i in (0..current_level.len()).step_by(2) {
                if i + 1 < current_level.len() {
                    let combined = if use_sha256 {
                        let concat = format!("{}{}", current_level[i], current_level[i + 1]);
                        let hash_bytes = env::sha256(concat.as_bytes());
                        Self::bytes_to_hex(&hash_bytes)
                    } else {
                        format!("{}{}", current_level[i], current_level[i + 1])
                    };
                    next_level.push(combined);
                } else {
                    next_level.push(current_level[i].clone());
                }
            }
            tree.push(next_level.clone());
            current_level = next_level;
        }
        let mut proof = vec![];
        let mut current_index = tx_index;
        for level in 0..(tree.len() - 1) {
            let level_size = tree[level].len() as u32;
            let sibling_index = if current_index % 2 == 0 {
                current_index + 1
            } else {
                current_index - 1
            };
            if sibling_index < level_size {
                proof.push(tree[level][sibling_index as usize].clone());
            }
            current_index /= 2;
        }
        proof
    }
    pub fn get_recent_batches(&self, limit: Option<u64>) -> Vec<BatchInfo> {
        let limit = limit.unwrap_or(20).min(RECENT_TOKENS_LIMIT) as usize;
        let start = self.recent_tokens.len().saturating_sub(limit as u32);
        (start..self.recent_tokens.len())
            .rev()
            .map(|i| {
                let token_id = self.recent_tokens.get(i as u32).unwrap();
                self.get_batch_info(token_id)
            })
            .collect()
    }
    pub fn get_batches_by_database(
        &self,
        database: String,
        from_index: Option<u64>,
        limit: Option<u64>,
    ) -> BatchSearchResult {
        let limit = limit.unwrap_or(50).min(100) as usize;
        let from_index = from_index.unwrap_or(0) as usize;
        let db_tokens = match self.tokens_by_database.get(&database) {
            Some(tokens) => tokens,
            None => {
                return BatchSearchResult {
                    batches: vec![],
                    total_count: 0,
                    has_more: false,
                };
            }
        };
        let total = db_tokens.len() as u64;
        let tokens: Vec<BatchInfo> = db_tokens
            .iter()
            .skip(from_index)
            .take(limit)
            .map(|token_id| self.get_batch_info(token_id))
            .collect();
        BatchSearchResult {
            batches: tokens,
            total_count: total,
            has_more: from_index + limit < total as usize,
        }
    }
    pub fn get_batches_by_time_range(
        &self,
        start_timestamp: u64,
        end_timestamp: u64,
        database: Option<String>,
        limit: Option<u64>,
    ) -> Vec<BatchInfo> {
        let limit = limit.unwrap_or(100).min(1000) as usize;
        self.tokens_by_timestamp
            .iter()
            .filter(|(ts, _)| **ts >= start_timestamp && **ts <= end_timestamp)
            .filter_map(|(_, token_id)| {
                let summary = self.batch_summaries.get(token_id)?;
                if let Some(ref db) = database {
                    if &summary.database_name != db {
                        return None;
                    }
                }
                Some(self.get_batch_info(token_id))
            })
            .take(limit)
            .collect()
    }
    pub fn get_batches_by_table(
        &self,
        table_name: String,
        limit: Option<u64>,
    ) -> Vec<BatchInfo> {
        let limit = limit.unwrap_or(50).min(100) as usize;
        self.tokens_by_table
            .get(&table_name)
            .map(|tokens| {
                tokens.iter()
                    .take(limit)
                    .map(|token_id| self.get_batch_info(token_id))
                    .collect()
            })
            .unwrap_or_default()
    }
    pub fn get_batch_stats(&self, token_id: Option<TokenId>) -> serde_json::Value {
        if let Some(tid) = token_id {
            let summary = self.batch_summaries.get(&tid)
                .expect("Batch not found");
            json!({
                "token_id": tid,
                "database": summary.database_name,
                "transaction_count": summary.tx_count,
                "merkle_root": summary.merkle_root,
                "timestamp": summary.timestamp,
                "operations": {
                    "inserts": summary.operation_counts.inserts,
                    "updates": summary.operation_counts.updates,
                    "deletes": summary.operation_counts.deletes,
                }
            })
        } else {
            let total_batches = self.tokens.nft_total_supply();
            let total_databases = self.database_list.len();
            json!({
                "total_batches": total_batches,
                "total_databases": total_databases,
                "databases": self.database_list.iter().cloned().collect::<Vec<_>>(),
            })
        }
    }
    pub fn get_databases(&self) -> Vec<String> {
        self.database_list.iter().cloned().collect()
    }
    pub fn get_batch_summary(&self, token_id: TokenId) -> Option<BatchSummary> {
        self.batch_summaries.get(&token_id).cloned()
    }
    #[private]
    pub fn set_paused(&mut self, paused: bool) {
        self.etrap_settings.paused = paused;
    }
    pub fn get_settings(&self) -> serde_json::Value {
        json!({
            "etrap_treasury": self.etrap_settings.etrap_treasury,
            "fee_amount": self.etrap_settings.fee_amount.as_yoctonear().to_string(),
            "paused": self.etrap_settings.paused
        })
    }
    #[private]
    pub fn update_treasury(&mut self, new_treasury: AccountId) {
        self.etrap_settings.etrap_treasury = new_treasury;
    }
}
#[near_bindgen]
impl NonFungibleTokenCore for ETRAPContract {
    #[payable]
    fn nft_transfer(
        &mut self,
        receiver_id: AccountId,
        token_id: TokenId,
        approval_id: Option<u64>,
        memo: Option<String>,
    ) {
        self.tokens.nft_transfer(receiver_id, token_id, approval_id, memo)
    }
    #[payable]
    fn nft_transfer_call(
        &mut self,
        receiver_id: AccountId,
        token_id: TokenId,
        approval_id: Option<u64>,
        memo: Option<String>,
        msg: String,
    ) -> PromiseOrValue<bool> {
        self.tokens.nft_transfer_call(receiver_id, token_id, approval_id, memo, msg)
    }
    fn nft_token(&self, token_id: TokenId) -> Option<Token> {
        self.tokens.nft_token(token_id)
    }
}
#[near_bindgen]
impl NonFungibleTokenResolver for ETRAPContract {
    #[private]
    fn nft_resolve_transfer(
        &mut self,
        previous_owner_id: AccountId,
        receiver_id: AccountId,
        token_id: TokenId,
        approved_account_ids: Option<HashMap<AccountId, u64>>,
    ) -> bool {
        self.tokens.nft_resolve_transfer(
            previous_owner_id,
            receiver_id,
            token_id,
            approved_account_ids,
        )
    }
}
#[near_bindgen]
impl NonFungibleTokenMetadataProvider for ETRAPContract {
    fn nft_metadata(&self) -> NFTContractMetadata {
        self.metadata.clone()
    }
}
#[near_bindgen]
impl NonFungibleTokenEnumeration for ETRAPContract {
    fn nft_total_supply(&self) -> U128 {
        self.tokens.nft_total_supply()
    }
    fn nft_tokens(&self, from_index: Option<U128>, limit: Option<u64>) -> Vec<Token> {
        self.tokens.nft_tokens(from_index, limit)
    }
    fn nft_supply_for_owner(&self, account_id: AccountId) -> U128 {
        self.tokens.nft_supply_for_owner(account_id)
    }
    fn nft_tokens_for_owner(
        &self,
        account_id: AccountId,
        from_index: Option<U128>,
        limit: Option<u64>,
    ) -> Vec<Token> {
        self.tokens.nft_tokens_for_owner(account_id, from_index, limit)
    }
}