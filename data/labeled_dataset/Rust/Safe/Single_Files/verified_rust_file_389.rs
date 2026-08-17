use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::UnorderedMap;
use near_sdk::json_types::{U128, U64};
use near_sdk::serde::{Deserialize, Serialize};
use near_sdk::{env, near_bindgen, AccountId, Balance, Promise};
#[derive(Deserialize, Serialize)]
#[serde(crate = "near_sdk::serde")]
struct JsonContract {
    pub owner_id: AccountId,
    pub user_collateral: Vec<(String, u128)>,
    pub loan_amount: U128,
    pub deadline: U64,
    pub settlement_status: bool,
}
#[derive(BorshDeserialize, BorshSerialize)]
#[near_bindgen]
struct Contract {
    pub owner_id: AccountId,
    pub user_collateral: UnorderedMap<AccountId, Balance>,
    pub loan_amount: u128,
    pub deadline: Option<u64>,
    pub settlement_status: bool,
}
#[derive(BorshDeserialize, BorshSerialize)]
pub enum StorageKey {
    UserBalanceKey,
}
impl Default for Contract {
    fn default() -> Self {
        env::panic(b"Contract should be initialized before usage")
    }
}
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new(owner_id: AccountId, deadline: Option<u64>) -> Self {
        Self {
            owner_id: owner_id,
            user_collateral: UnorderedMap::new(StorageKey::UserBalanceKey.try_to_vec().unwrap()),
            loan_amount: 0,
            deadline: deadline,
            settlement_status: false,
        }
    }
    pub fn update_deadline(&mut self, new_deadline: u64) {
        assert_eq!(
            self.owner_id,
            env::predecessor_account_id(),
            "Only owner can update deadline"
        );
        self.deadline = Some(new_deadline);
    }
    #[payable]
    pub fn deposit_loan(&mut self) {
        assert_eq!(
            self.owner_id,
            env::predecessor_account_id(),
            "Only owner can loan to other"
        );
        self.loan_amount += env::attached_deposit();
    }
    pub fn add_user(&mut self, user: AccountId) {
        assert_eq!(
            self.owner_id,
            env::predecessor_account_id(),
            "Only owner can add other users"
        );
        self.user_collateral.insert(&user, &0);
    }
    #[payable]
    pub fn deposit_collateral(&mut self) {
        let balance = env::attached_deposit();
        let user = env::predecessor_account_id();
        assert!(
            self.user_collateral.insert(&user, &balance).is_some(),
            "Users need to be added by owner"
        );
    }
    #[payable]
    pub fn borrowing(&mut self) {
        assert!(self.loan_amount > 0, "There is no fund available to borrow");
        assert!(
            env::block_timestamp() <= self.deadline.unwrap(),
            "Pass the deadline, cannot borrowing"
        );
        assert!(
            self.user_collateral
                .get(&env::predecessor_account_id())
                .unwrap_or(0)
                > 0,
            "User need to deposit collateral first"
        );
        let borrower = env::predecessor_account_id();
        let users = self.user_collateral.keys_as_vector();
        assert!(
            users.iter().any(|user| user == borrower),
            "Borrower is not in the user list"
        );
        Promise::new(borrower).transfer(self.loan_amount);
    }
    #[payable]
    pub fn settlement(&mut self) {
        if env::block_timestamp() <= self.deadline.unwrap() {
            self.paid_loan();
            self.settlement_status = true;
        } else {
            if env::predecessor_account_id() != self.owner_id {
                self.paid_loan();
            }
            self.settlement_status = false;
        }
        self.return_deposit()
    }
    fn paid_loan(&mut self) {
        let loan_amount = self.loan_amount;
        assert!(
            env::attached_deposit() >= loan_amount,
            "The attached deposit is lower than the loan amount"
        );
        Promise::new(self.owner_id.clone()).transfer(loan_amount);
    }
    fn return_deposit(&mut self) {
        if self.settlement_status {
            self.return_to_users()
        } else {
            self.return_to_owners()
        }
    }
    fn return_to_users(&mut self) {
        let user_balance = &self.user_collateral;
        for user in user_balance.keys() {
            Promise::new(user.clone()).transfer(user_balance.get(&user).unwrap());
        }
        self.user_collateral = UnorderedMap::new(StorageKey::UserBalanceKey.try_to_vec().unwrap());
    }
    fn return_to_owners(&mut self) {
        let user_balance = &self.user_collateral;
        let mut return_balance = 0;
        for user in user_balance.keys() {
            return_balance += user_balance.get(&user).unwrap();
        }
        Promise::new(self.owner_id.clone()).transfer(return_balance);
        self.user_collateral = UnorderedMap::new(StorageKey::UserBalanceKey.try_to_vec().unwrap());
    }
    pub fn get_block_timestamp(&self) -> u64 {
        let time = env::block_timestamp();
        time
    }
    pub fn get_contract_info(&self) -> JsonContract {
        JsonContract {
            owner_id: self.owner_id.clone(),
            user_collateral: self.user_collateral.to_vec(),
            loan_amount: U128(self.loan_amount),
            deadline: U64(self.deadline.unwrap_or(0)),
            settlement_status: self.settlement_status,
        }
    }
}