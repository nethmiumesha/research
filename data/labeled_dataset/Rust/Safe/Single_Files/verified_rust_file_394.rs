use std::ptr::addr_of_mut;
use near_contract_standards::fungible_token::metadata::{
    FungibleTokenMetadata, FungibleTokenMetadataProvider,
};
use near_contract_standards::fungible_token::FungibleToken;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::LazyOption;
use near_sdk::json_types::{ValidAccountId, U128};
use near_sdk::{
  assert_one_yocto, assert_self, env, ext_contract, near_bindgen, AccountId, PanicOnDefault,
  PromiseOrValue,
};
near_sdk::setup_alloc!();
const T_GAS: u64 = 1_000_000_000_000;
#[near_bindgen]
#[derive(BorshSerialize, BorshDeserialize, PanicOnDefault)]
pub struct ElectronTestToken {
    token: FungibleToken,
    metadata: LazyOption<FungibleTokenMetadata>,
    owner_id: AccountId,
}
#[near_bindgen]
impl ElectronTestToken {
    #[init]
    pub fn new(
        owner_id: ValidAccountId,
        metadata: FungibleTokenMetadata,
        premined_owner_balance: U128,
    ) -> Self {
        assert!(!env::state_exists(), "Already initialized.");
        metadata.assert_valid();
        let mut this = Self {
            token: FungibleToken::new(b"a".to_vec()),
            metadata: LazyOption::new(b"m".to_vec(), Some(&metadata)),
            owner_id: owner_id.clone().into(),
        };
        this.token.internal_register_account(&env::current_account_id());
        this.token.internal_register_account(owner_id.as_ref());
        this.internal_mint(owner_id.clone(), premined_owner_balance);
        this
    }
    pub fn register_account(&mut self, account_id: AccountId) {
        self.assert_owner();
        self.token.internal_register_account(&account_id);
    }
    #[payable]
    pub fn mint(&mut self, account_id: ValidAccountId, amount: U128) {
        self.assert_owner();
        match self.token.accounts.get(&account_id.to_string()) {
            None => self.register_account(account_id.clone().to_string()),
            _ => (),
        };
        self.internal_mint(account_id, amount);
    }
    fn internal_mint(&mut self, account_id: ValidAccountId, amount: U128) {
        self.token.internal_deposit(account_id.as_ref(), amount.into());
    }
    #[payable]
    pub fn burn(&mut self, account_id: ValidAccountId, amount: U128) {
        assert_one_yocto();
        self.assert_owner();
        self.token.internal_withdraw(account_id.as_ref(), amount.into());
    }
    pub fn set_icon(&mut self, icon: String) {
        assert_self();
        let mut metadata = self.metadata.get().unwrap();
        metadata.icon = Some(icon);
        self.metadata.set(&metadata);
    }
}
pub trait Ownable {
    fn assert_owner(&self) {
        assert_eq!(
            env::predecessor_account_id(),
            self.get_owner(),
            "Only owner can call mint."
        );
    }
    fn get_owner(&self) -> AccountId;
    fn set_owner(&mut self, owner_id: AccountId);
}
#[near_bindgen]
impl Ownable for ElectronTestToken {
    fn get_owner(&self) -> AccountId {
        self.owner_id.clone()
    }
    fn set_owner(&mut self, owner_id: AccountId) {
        self.assert_owner();
        self.owner_id = owner_id;
    }
}
near_contract_standards::impl_fungible_token_core!(ElectronTestToken, token);
near_contract_standards::impl_fungible_token_storage!(ElectronTestToken, token);
#[near_bindgen]
impl FungibleTokenMetadataProvider for ElectronTestToken {
    fn ft_metadata(&self) -> FungibleTokenMetadata {
        self.metadata.get().unwrap()
    }
}