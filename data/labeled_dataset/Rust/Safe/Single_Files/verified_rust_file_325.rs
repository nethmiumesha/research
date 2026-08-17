use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::Vector;
use near_sdk::json_types::{U128, U64};
use near_sdk::{env, log, near_bindgen, AccountId, Balance, PanicOnDefault, Promise, StorageUsage};
pub mod proposal;
use crate::proposal::*;
pub mod config;
use crate::config::*;
near_sdk::setup_alloc!();
const STORAGE_PRICE_PER_BYTE: Balance = env::STORAGE_PRICE_PER_BYTE;
#[near_bindgen]
#[derive(BorshSerialize, BorshDeserialize, PanicOnDefault)]
pub struct Contract {
    deployer_id: AccountId,
    members: Vec<Voter>,
    min_support: u32,
    min_duration: u32,
    max_duration: u32,
    min_bond: Balance,
    next_idx: u32,
    proposals: Vector<Proposal>,
}
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new(
        members: Vec<Voter>,
        min_support: u32,
        min_duration: u32,
        max_duration: u32,
        min_bond: U128,
    ) -> Self {
        assert!(min_support > 0, "min_support must be positive");
        for s in &members {
            assert_valid_account(&s.account);
        }
        assert!(
            min_duration >= 2 && max_duration > min_duration,
            "min_duration and max_duration must be at least 2"
        );
        let min_bond: u128 = min_bond.into();
        assert!(
            min_bond > STORAGE_PRICE_PER_BYTE,
            "min_bond must be bigger than {}",
            STORAGE_PRICE_PER_BYTE
        );
        Self {
            deployer_id: env::predecessor_account_id(),
            members,
            min_support,
            min_duration,
            max_duration,
            min_bond,
            next_idx: 0,
            proposals: Vector::new("p".into()),
        }
    }
    #[payable]
    pub fn add_proposal(&mut self, p: NewProposal) -> u32 {
        let storage_start = env::storage_usage();
        self.proposals
            .push(&p.into_proposal(self.min_duration, self.max_duration));
        log!(
            "New proposal added at timestamp={}seconds, id={}.",
            env::block_timestamp(),
            self.next_idx
        );
        self.next_idx += 1;
        self.refund_storage(storage_start, true);
        return self.next_idx - 1;
    }
    #[payable]
    pub fn vote(&mut self, proposal_id: u32, support: bool) {
        let a = env::predecessor_account_id();
        let mut voter_o: Option<&Voter> = None;
        for s in &self.members {
            if s.account == a {
                voter_o = Some(s);
                break;
            }
        }
        let voter = voter_o.expect(&format!("you ({}) are not authorized to vote", a));
        let idx: u64 = proposal_id.into();
        let p = &mut self.proposals.get(idx).expect("proposal_id not found");
        let storage_start = env::storage_usage();
        p.vote(voter, support);
        self.proposals.replace(idx, p);
        self.refund_storage(storage_start, false);
    }
    pub fn execute(&mut self, proposal_id: u32) -> Promise {
        let idx: u64 = proposal_id.into();
        let p = &mut self.proposals.get(idx).expect("proposal_id not found");
        let promise = p.execute(self.min_support);
        self.proposals.replace(idx, p);
        log!("Proposal {} executed.", proposal_id);
        return promise;
    }
    pub fn proposal(&self, proposal_id: u32) -> ProposalOut {
        assert!(proposal_id < self.next_idx, "proposal_id not found");
        let idx: u64 = proposal_id.into();
        let p = self.proposals.get(idx).expect("proposal_id not found");
        p.into()
    }
    pub fn settings(&self) -> Settings {
        Settings {
            deployer_id: self.deployer_id.clone(),
            members: serde_json::to_string(&self.members).unwrap(),
            min_support: self.min_support,
            min_duration: self.min_duration,
            max_duration: self.max_duration,
            min_bond: self.min_bond.into(),
            unix_time: U64::from(env::block_timestamp() / FROM_NANO),
        }
    }
    fn refund_storage(&self, initial_storage: StorageUsage, check_bond: bool) {
        let current_storage = env::storage_usage();
        let attached_deposit = env::attached_deposit();
        let refund_amount = if current_storage > initial_storage {
            let mut required_deposit =
                Balance::from(current_storage - initial_storage) * STORAGE_PRICE_PER_BYTE;
            if check_bond && required_deposit < self.min_bond {
                required_deposit = self.min_bond
            }
            assert!(
                required_deposit <= attached_deposit,
                "The required attached deposit is {}, but the given attached deposit is is {}",
                required_deposit,
                attached_deposit,
            );
            attached_deposit - required_deposit
        } else {
            attached_deposit
                + Balance::from(initial_storage - current_storage) * STORAGE_PRICE_PER_BYTE
        };
        if refund_amount > 0 {
            Promise::new(env::predecessor_account_id()).transfer(refund_amount);
        }
    }
}