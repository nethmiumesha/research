use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::serde::{Deserialize, Serialize};
#[derive(BorshDeserialize, BorshSerialize, Clone, Debug, Default, Deserialize, Serialize)]
#[serde(crate = "near_sdk::serde")]
pub struct RlpEncode;
impl RlpEncode {
    pub const LIST_SHORT_START: u8 = 0xc0;
    pub const LIST_LONG_START: u8 = 0xf7;
    const MAX_UINT8: u8 = u8::MAX;
    const MAX_UINT16: u16 = u16::MAX;
    const MAX_UINT32: u32 = u32::MAX;
    const MAX_UINT64: u64 = u64::MAX;
    const MAX_UINT128: u128 = u128::MAX;
    fn get_rlp_encoded(&self) -> Vec<u8> {
        Self::try_to_vec(self).expect("Failed to serialize RlpEncode")
    }
    pub fn encode_bytes(bytes: Self) -> Vec<u8> {
        let encoded: Vec<u8>;
        let rlp = bytes.get_rlp_encoded();
        if rlp.len() == 1 && rlp[0] <= 128 {
            encoded = rlp.clone();
        } else {
            encoded = Self::concat(&Self::encode_length(rlp.len(), 128), &rlp);
        }
        encoded
    }
    pub fn encode_list(bytes: Vec<Self>) -> Vec<u8> {
        let mut rlp_list: Vec<Vec<u8>> = vec![];
        for entry in bytes {
            let rlp = entry.get_rlp_encoded();
            rlp_list.push(rlp);
        }
        let list = Self::flatten(rlp_list);
        Self::concat(&Self::encode_length(list.len(), 192), &list)
    }
    pub fn encode_uint(item: Self) -> Vec<u8> {
        let rlp_encode = item.get_rlp_encoded();
        let n_bytes = Self::bit_length(rlp_encode.len()) / 8 + 1;
        let uint_bytes = Self::encode_uint_by_length(rlp_encode.len());
        if n_bytes - uint_bytes.len() > 0 {}
        Self::encode_bytes(item)
    }
    pub fn encode_int() -> Vec<u8> {
        todo!()
    }
    pub fn encode_bool() -> Vec<u8> {
        todo!()
    }
    fn encode_length(len: usize, offset: usize) -> Vec<u8> {
        todo!()
    }
    fn to_binary(x: usize) -> Vec<u8> {
        todo!()
    }
    fn memcpy(dest: usize, src: usize, len: usize) {
        todo!()
    }
    fn flatten(list: Vec<Vec<u8>>) -> Vec<u8> {
        todo!()
    }
    fn concat(before: &[u8], after: &[u8]) -> Vec<u8> {
        todo!()
    }
    fn add_length(length: usize, is_long_list: bool) -> Vec<u8> {
        todo!()
    }
    fn encode_uint_by_length(length: usize) -> Vec<u8> {
        todo!()
    }
    fn bit_length(n: usize) -> usize {
        todo!()
    }
}