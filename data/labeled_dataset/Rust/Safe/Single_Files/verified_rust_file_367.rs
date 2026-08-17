use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::serde::Serialize;
use near_sdk::{env, near_bindgen, AccountId};
use std::collections::HashMap;
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize)]
pub struct Contract {
    scoreboard: HashMap<AccountId, u32>,
}
impl Default for Contract {
    fn default() -> Self {
        Self {
            scoreboard: HashMap::new(),
        }
    }
}
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, Serialize)]
#[serde(crate = "near_sdk::serde")]
pub struct PlayerScore {
    player: AccountId,
    score: u32,
}
#[near_bindgen]
impl Contract {
    pub fn get_scores(&self) -> Vec<PlayerScore> {
        let mut scores: Vec<PlayerScore> = Vec::new();
        for (key, value) in &self.scoreboard {
            scores.push(PlayerScore {
                player: key.clone(),
                score: value.clone(),
            });
        }
        scores.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap());
        return scores;
    }
    pub fn set_score(&mut self, score: u32) {
        let player = env::predecessor_account_id();
        let existing_score = self.scoreboard.entry(player).or_default();
        if score > *existing_score {
            *existing_score = score;
        }
    }
}