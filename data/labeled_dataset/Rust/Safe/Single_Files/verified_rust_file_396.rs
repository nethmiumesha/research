use crate::*;
use near_sdk::near_bindgen;
#[near_bindgen]
impl KeyValueContract {
    pub fn set_keys(&mut self, data: HashMap<String, String>) {
        self.assert_owner();
        env::log(format!("Extending store with data {:?}.", data).as_bytes());
        self.store.extend(data.into_iter());
    }
    pub fn delete_keys(&mut self, keys: Vec<String>) {
        self.assert_owner();
        env::log(format!("Deleting keys {:?} from store.", keys).as_bytes());
        for key in keys.iter() {
            self.store.remove(key);
        }
    }
    pub fn clear_store(&mut self) {
        self.assert_owner();
        env::log(format!("Clearing entire store.").as_bytes());
        self.store.clear();
    }
}