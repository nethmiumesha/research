use near_contract_standards::fungible_token::metadata::{
    FungibleTokenMetadata, FungibleTokenMetadataProvider, FT_METADATA_SPEC,
};
use near_contract_standards::fungible_token::FungibleToken;
use near_sdk::borsh::{self, BorshDeserialize, BorshSerialize};
use near_sdk::collections::LazyOption;
use near_sdk::json_types::U128;
use near_sdk::{env, log, near_bindgen, AccountId, Balance, PanicOnDefault, PromiseOrValue};
#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
pub struct Contract {
    owner: AccountId,
    token: FungibleToken,
    metadata: LazyOption<FungibleTokenMetadata>,
}
const DATA_IMAGE_SVG_NEAR_ICON: &str = "data:image/png;base64,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
#[near_bindgen]
impl Contract {
    #[init]
    pub fn new_default_meta(owner_id: AccountId, _total_supply: U128) -> Self {
        Self::new(
            owner_id,
            U128::from(0),
            FungibleTokenMetadata {
                spec: FT_METADATA_SPEC.to_string(),
                name: "INIT Token".to_string(),
                symbol: "INIT".to_string(),
                icon: Some(DATA_IMAGE_SVG_NEAR_ICON.to_string()),
                reference: None,
                reference_hash: None,
                decimals: 24,
            },
        )
    }
    #[init]
    pub fn new(
        owner_id: AccountId,
        total_supply: U128,
        metadata: FungibleTokenMetadata,
    ) -> Self {
        assert!(!env::state_exists(), "Already initialized");
        metadata.assert_valid();
        let mut this = Self {
            owner: owner_id,
            token: FungibleToken::new(b"a".to_vec()),
            metadata: LazyOption::new(b"m".to_vec(), Some(&metadata)),
        };
        this.token.internal_register_account(&this.owner);
        this.token.internal_deposit(&this.owner, total_supply.into());
        near_contract_standards::fungible_token::events::FtMint {
            owner_id: &this.owner,
            amount: &total_supply,
            memo: Some("Initial tokens supply is minted"),
        }
        .emit();
        this
    }
    fn on_account_closed(&mut self, account_id: AccountId, balance: Balance) {
        log!("Closed @{} with {}", account_id, balance);
    }
    fn on_tokens_burned(&mut self, account_id: AccountId, amount: Balance) {
        log!("Account @{} burned {}", account_id, amount);
    }
}
near_contract_standards::impl_fungible_token_core!(Contract, token, on_tokens_burned);
near_contract_standards::impl_fungible_token_storage!(Contract, token, on_account_closed);
#[near_bindgen]
impl FungibleTokenMetadataProvider for Contract {
    fn ft_metadata(&self) -> FungibleTokenMetadata {
        self.metadata.get().unwrap()
    }
}
#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use near_sdk::test_utils::{accounts, VMContextBuilder};
    use near_sdk::MockedBlockchain;
    use near_sdk::{testing_env, Balance};
    use super::*;
    const TOTAL_SUPPLY: Balance = 1_000_000_000;
    fn get_context(predecessor_account_id: AccountId) -> VMContextBuilder {
        let mut builder = VMContextBuilder::new();
        builder
            .current_account_id(accounts(0))
            .signer_account_id(predecessor_account_id.clone())
            .predecessor_account_id(predecessor_account_id);
        builder
    }
    #[test]
    fn test_new() {
        let mut context = get_context(accounts(1));
        testing_env!(context.build());
        let contract = Contract::new_default_meta(accounts(1).into(), TOTAL_SUPPLY.into());
        testing_env!(context.is_view(true).build());
        assert_eq!(contract.ft_total_supply().0, TOTAL_SUPPLY);
        assert_eq!(contract.ft_balance_of(accounts(1)).0, TOTAL_SUPPLY);
    }
    #[test]
    #[should_panic(expected = "The contract is not initialized")]
    fn test_default() {
        let context = get_context(accounts(1));
        testing_env!(context.build());
        let _contract = Contract::default();
    }
    #[test]
    fn test_transfer() {
        let mut context = get_context(accounts(2));
        testing_env!(context.build());
        let mut contract = Contract::new_default_meta(accounts(2).into(), TOTAL_SUPPLY.into());
        testing_env!(context
            .storage_usage(env::storage_usage())
            .attached_deposit(contract.storage_balance_bounds().min.into())
            .predecessor_account_id(accounts(1))
            .build());
        contract.storage_deposit(None, None);
        testing_env!(context
            .storage_usage(env::storage_usage())
            .attached_deposit(1)
            .predecessor_account_id(accounts(2))
            .build());
        let transfer_amount = TOTAL_SUPPLY / 3;
        contract.ft_transfer(accounts(1), transfer_amount.into(), None);
        testing_env!(context
            .storage_usage(env::storage_usage())
            .account_balance(env::account_balance())
            .is_view(true)
            .attached_deposit(0)
            .build());
        assert_eq!(contract.ft_balance_of(accounts(2)).0, (TOTAL_SUPPLY - transfer_amount));
        assert_eq!(contract.ft_balance_of(accounts(1)).0, transfer_amount);
    }
}