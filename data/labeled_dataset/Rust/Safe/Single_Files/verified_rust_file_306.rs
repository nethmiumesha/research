use crate::*;
use near_sdk::{json_types::U128, near_bindgen, AccountId};
use std::collections::HashMap;
#[derive(Serialize, Deserialize)]
#[serde(crate = "near_sdk::serde")]
pub struct Summary {
    pub total_share_amount: U128,
    pub total_staked_near_amount: U128,
    pub ft_price: U128,
    pub validators_num: u64,
    pub stake_amount_to_settle: U128,
    pub unstake_amount_to_settle: U128,
    pub validators_total_base_stake_amount: U128,
    pub epoch_requested_stake_amount: U128,
    pub epoch_requested_unstake_amount: U128,
}
#[near_bindgen]
impl LiquidStakingContract {
    pub fn get_total_share_amount(&self) -> U128 {
        self.total_share_amount.into()
    }
    pub fn get_beneficiaries(&self) -> HashMap<AccountId, u32> {
        self.internal_get_beneficiaries()
    }
    pub fn get_managers(&self) -> Vec<AccountId> {
        self.internal_get_managers()
    }
    pub fn get_summary(&self) -> Summary {
        Summary {
            total_share_amount: self.total_share_amount.into(),
            total_staked_near_amount: self.total_staked_near_amount.into(),
            ft_price: self.ft_price(),
            validators_num: self.validator_pool.count(),
            stake_amount_to_settle: self.stake_amount_to_settle.into(),
            unstake_amount_to_settle: self.unstake_amount_to_settle.into(),
            validators_total_base_stake_amount: self.validator_pool.total_base_stake_amount.into(),
            epoch_requested_stake_amount: self.epoch_requested_stake_amount.into(),
            epoch_requested_unstake_amount: self.epoch_requested_unstake_amount.into(),
        }
    }
    pub fn get_account_details(&self, account_id: AccountId) -> AccountDetailsView {
        let account = self.internal_get_account(&account_id);
        AccountDetailsView {
            account_id,
            unstaked_balance: account.unstaked.into(),
            staked_balance: self
                .staked_amount_from_num_shares_rounded_down(account.stake_shares)
                .into(),
            unstaked_available_epoch_height: account.unstaked_available_epoch_height,
            can_withdraw: account.unstaked_available_epoch_height <= get_epoch_height(),
        }
    }
    pub fn get_account_unstaked_balance(&self, account_id: AccountId) -> U128 {
        self.get_account(account_id).unstaked_balance
    }
    pub fn get_account_staked_balance(&self, account_id: AccountId) -> U128 {
        self.get_account(account_id).staked_balance
    }
    pub fn get_account_total_balance(&self, account_id: AccountId) -> U128 {
        let account = self.get_account(account_id);
        (account.unstaked_balance.0 + account.staked_balance.0).into()
    }
    pub fn is_account_unstaked_balance_available(&self, account_id: AccountId) -> bool {
        self.get_account(account_id).can_withdraw
    }
    pub fn get_total_staked_balance(&self) -> U128 {
        self.total_staked_near_amount.into()
    }
    pub fn get_owner_id(&self) -> AccountId {
        self.owner_id.clone()
    }
    pub fn get_reward_fee_fraction(&self) -> Fraction {
        Fraction {
            numerator: 58,
            denominator: 1000,
        }
    }
    pub fn get_staking_key(&self) -> PublicKey {
        panic!("no need to specify public key for liquid staking pool");
    }
    pub fn is_paused(&self) -> bool {
        self.paused
    }
    pub fn get_account(&self, account_id: AccountId) -> HumanReadableAccount {
        let account = self.internal_get_account(&account_id);
        HumanReadableAccount {
            account_id,
            unstaked_balance: account.unstaked.into(),
            staked_balance: self
                .staked_amount_from_num_shares_rounded_down(account.stake_shares)
                .into(),
            can_withdraw: account.unstaked_available_epoch_height <= get_epoch_height(),
        }
    }
    pub fn get_number_of_accounts(&self) -> u64 {
        self.accounts.len()
    }
    pub fn get_accounts(&self, from_index: u64, limit: u64) -> Vec<HumanReadableAccount> {
        let keys = self.accounts.keys_as_vector();
        (from_index..std::cmp::min(from_index + limit, keys.len()))
            .map(|index| self.get_account(keys.get(index).unwrap()))
            .collect()
    }
    pub fn can_account_withdraw(&self, account_id: AccountId, amount: U128) {
        self.assert_can_withdraw(&account_id, amount.0);
    }
}