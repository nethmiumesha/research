use std::collections::HashSet;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
#[derive(Serialize, Deserialize)]
#[serde(crate = "near_sdk::serde")]
enum BountyStatus {
    Open,
    Claimed { account_id: AccountId, started: Timestamp },
    InReview { account_id: AccountId, started: Timestamp },
    Done,
    Expired,
}
#[derive(Serialize, Deserialize)]
#[serde(crate = "near_sdk::serde")]
pub struct Bounty {
    status: BountyStatus,
    description: String,
    duration: Duration,
    applicants: HashSet<AccountId>,
}