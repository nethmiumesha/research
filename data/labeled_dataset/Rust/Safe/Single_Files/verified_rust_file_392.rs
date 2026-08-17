use near_sdk::ext_contract;
use near_sdk::json_types::U128;
use near_sdk::AccountId;
use near_sdk::PromiseOrValue;
use near_contract_standards::fungible_token::metadata::FungibleTokenMetadata;
#[ext_contract(ext_mft_resolver)]
trait MftTokenResolver {
    fn mft_resolve_transfer(
        &mut self,
        token_id: String,
        sender_id: AccountId,
        receiver_id: AccountId,
        amount: U128,
    ) -> U128;
}
#[ext_contract(ext_mft_receiver)]
pub trait MftTokenReceiver {
    fn mft_on_transfer(
        &mut self,
        token_id: String,
        sender_id: AccountId,
        amount: U128,
        msg: String,
    ) -> PromiseOrValue<U128>;
}
#[ext_contract(ext_mft_core)]
pub trait MultiFungibleTokenCore {
    fn mft_balance_of(&self, token_id: String, account_id: AccountId) -> U128;
    fn mft_total_supply(&self, token_id: String) -> U128;
    fn mft_transfer(
        &mut self,
        token_id: String,
        receiver_id: AccountId,
        amount: U128,
        memo: Option<String>,
    );
    fn mft_transfer_call(
        &mut self,
        token_id: String,
        receiver_id: AccountId,
        amount: U128,
        memo: Option<String>,
        msg: String,
    ) -> PromiseOrValue<U128>;
    fn mft_resolve_transfer(
        &mut self,
        token_id: String,
        sender_id: AccountId,
        receiver_id: &AccountId,
        amount: U128,
    ) -> U128;
    fn mft_metadata(&self, token_id: String) -> FungibleTokenMetadata;
}