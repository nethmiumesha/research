use crate::*;
use near_sdk::{CryptoHash};
use std::mem::size_of;
pub(crate) fn hash_account_id(account_id: &AccountId) -> CryptoHash {
    let mut hash = CryptoHash::default();
    hash.copy_from_slice(&env::sha256(account_id.as_bytes()));
    hash
}
impl NFTLoans {
    pub(crate) fn internal_add_loan_to_owner(
        &mut self,
        account_id: &AccountId,
        loan_id: &LoanId,
    ) {
        let mut loans_set = self.loans_per_owner.get(account_id).unwrap_or_else(|| {
            UnorderedSet::new(
                StorageKey::LoanPerOwnerInner {
                    account_id_hash: hash_account_id(&account_id),
                }
                .try_to_vec()
                .unwrap(),
            )
        });
        loans_set.insert(loan_id);
        self.loans_per_owner.insert(account_id, &loans_set);
    }
    pub(crate) fn internal_remove_loan_from_owner(
        &mut self,
        account_id: &AccountId,
        loan_id: &LoanId,
    ) {
        let mut loans_set = self
            .loans_per_owner
            .get(account_id)
            .expect("Loan should be owned by the sender");
        loans_set.remove(loan_id);
        if loans_set.is_empty() {
            self.loans_per_owner.remove(account_id);
        } else {
            self.loans_per_owner.insert(account_id, &loans_set);
        }
    }
    pub(crate) fn internal_add_loan_to_lender(
        &mut self,
        account_id: &AccountId,
        loan_id: &LoanId,
    ) {
        let mut loans_set = self.loans_per_lender.get(account_id).unwrap_or_else(|| {
            UnorderedSet::new(
                StorageKey::LoanPerLenderInner {
                    account_id_hash: hash_account_id(&account_id),
                }
                .try_to_vec()
                .unwrap(),
            )
        });
        loans_set.insert(loan_id);
        self.loans_per_lender.insert(account_id, &loans_set);
    }
    pub(crate) fn internal_remove_loan_from_lender(
        &mut self,
        account_id: &AccountId,
        loan_id: &LoanId,
    ) {
        let mut loans_set = self
            .loans_per_lender
            .get(account_id)
            .expect("Loan should be lended by the sender");
        loans_set.remove(loan_id);
        if loans_set.is_empty() {
            self.loans_per_lender.remove(account_id);
        } else {
            self.loans_per_lender.insert(account_id, &loans_set);
        }
    }
}