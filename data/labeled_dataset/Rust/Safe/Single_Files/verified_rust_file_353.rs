use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::{env, log, near_bindgen, BlockHeight};
use rand_chacha::{self, rand_core::SeedableRng};
use rand_core::RngCore;
near_sdk::setup_alloc!();
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, Default)]
pub struct Contract {
    block_index: BlockHeight,
    seed: u64,
}
#[near_bindgen]
impl Contract {
    pub fn generate(&mut self) -> u64 {
        if env::block_index() != self.block_index {
            self.block_index = env::block_index();
            self.seed = u64::from_be_bytes((env::random_seed())[..8].try_into().unwrap());
        }
        let mut gen = rand_chacha::ChaCha12Rng::seed_from_u64(self.seed);
        self.seed = gen.next_u64();
        log!("Generated number: {}", self.seed);
        log!("Current block: {}", self.block_index);
        self.seed
    }
}