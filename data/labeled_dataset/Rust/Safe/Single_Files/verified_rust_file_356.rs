use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{near_bindgen, collections::UnorderedMap};
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct WebGuideContract {
    guides: UnorderedMap<String, String>,
}
impl Default for WebGuideContract {
    fn default() -> Self {
        Self {
            guides: UnorderedMap::new(b"g".to_vec()),
        }
    }
}
#[near_bindgen]
impl WebGuideContract {
    pub fn get_guide(&self, guide_id: String) -> Option<String> {
        self.guides.get(&guide_id)
    }
    pub fn set_guide(&mut self, guide_id: String, data: String) {
        self.guides.insert(&guide_id, &data);
    }
}