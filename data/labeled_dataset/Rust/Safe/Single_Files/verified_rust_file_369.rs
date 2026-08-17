use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{env, near_bindgen};
use near_sdk::collections::UnorderedSet;
#[global_allocator]
static ALLOC: near_sdk::wee_alloc::WeeAlloc = near_sdk::wee_alloc::WeeAlloc::INIT;
pub type HashedVector = String;
const HEX_CHARS_UPPER: &[u8; 16] = b"0123456789ABCDEF";
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct HashStorage {
    hash_storage: UnorderedSet<HashedVector>
}
impl Default for HashStorage {
    fn default() -> Self {
        HashStorage{ hash_storage: UnorderedSet::new(vec![]) }
    }
}
#[near_bindgen]
impl HashStorage {
    pub fn is_hash_exist(&self, hash: String) -> bool {
        self.hash_storage.contains(&hash)
    }
    pub fn store_hash(&mut self, raw_vector: Vec<u8>) -> String {
        if raw_vector.len() == 0 {
            env::panic(b"Vec is null.");
        }
        let hashed_vector = env::sha256(&*raw_vector);
        let mut stringified_hash = String::with_capacity(hashed_vector.len() * 2);
        for n in hashed_vector.iter() {
            stringified_hash.push(HEX_CHARS_UPPER[(n >> 4) as usize] as char);
            stringified_hash.push(HEX_CHARS_UPPER[(n & 0x0F) as usize] as char);
        }
        let is_hash_exist = self.hash_storage.contains(&stringified_hash);
        if is_hash_exist {
            env::panic(b"Hash already exist.");
        } else {
            self.hash_storage.insert(&stringified_hash);
            stringified_hash
        }
    }
}