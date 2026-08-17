use anchor_lang::prelude::{Id, System, ToAccountMetas};
use anchor_lang::InstructionData;
use anchor_spl::token::Token;
use solana_sdk::instruction::Instruction;
use solana_sdk::pubkey::Pubkey;
use solana_sdk::sysvar::{rent::Rent, SysvarId};
use jet_margin_pool::accounts as ix_accounts;
use jet_margin_pool::instruction as ix_data;
use jet_margin_pool::program::JetMarginPool;
use jet_margin_pool::Amount;
pub struct MarginPoolIxBuilder {
    pub token_mint: Pubkey,
    pub address: Pubkey,
    pub vault: Pubkey,
    pub deposit_note_mint: Pubkey,
    pub loan_note_mint: Pubkey,
}
impl MarginPoolIxBuilder {
    pub fn new(token_mint: Pubkey) -> Self {
        let (address, _) =
            Pubkey::find_program_address(&[token_mint.as_ref()], &JetMarginPool::id());
        let (vault, _) = Pubkey::find_program_address(
            &[address.as_ref(), b"vault".as_ref()],
            &JetMarginPool::id(),
        );
        let (deposit_note_mint, _) = Pubkey::find_program_address(
            &[address.as_ref(), b"deposit-notes".as_ref()],
            &JetMarginPool::id(),
        );
        let (loan_note_mint, _) = Pubkey::find_program_address(
            &[address.as_ref(), b"loan-notes".as_ref()],
            &JetMarginPool::id(),
        );
        Self {
            token_mint,
            address,
            vault,
            deposit_note_mint,
            loan_note_mint,
        }
    }
    pub fn create(&self, payer: Pubkey) -> Instruction {
        let authority = match cfg!(feature = "devnet") {
            true => payer,
            false => jet_margin_pool::authority::ID,
        };
        let accounts = ix_accounts::CreatePool {
            authority,
            token_mint: self.token_mint,
            margin_pool: self.address,
            deposit_note_mint: self.deposit_note_mint,
            loan_note_mint: self.loan_note_mint,
            vault: self.vault,
            payer,
            token_program: Token::id(),
            system_program: System::id(),
            rent: Rent::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::CreatePool {}.data(),
            accounts,
        }
    }
    pub fn deposit(
        &self,
        depositor: Pubkey,
        source: Pubkey,
        destination: Pubkey,
        amount: u64,
    ) -> Instruction {
        let accounts = ix_accounts::Deposit {
            margin_pool: self.address,
            vault: self.vault,
            deposit_note_mint: self.deposit_note_mint,
            depositor,
            source,
            destination,
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::Deposit { amount }.data(),
            accounts,
        }
    }
    pub fn withdraw(
        &self,
        depositor: Pubkey,
        source: Pubkey,
        destination: Pubkey,
        amount: Amount,
    ) -> Instruction {
        let accounts = ix_accounts::Withdraw {
            margin_pool: self.address,
            vault: self.vault,
            deposit_note_mint: self.deposit_note_mint,
            depositor,
            source,
            destination,
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::Withdraw { amount }.data(),
            accounts,
        }
    }
    pub fn margin_borrow(
        &self,
        margin_account: Pubkey,
        deposit_account: Pubkey,
        loan_account: Pubkey,
        amount: u64,
    ) -> Instruction {
        let accounts = ix_accounts::MarginBorrow {
            margin_account,
            margin_pool: self.address,
            loan_note_mint: self.loan_note_mint,
            deposit_note_mint: self.deposit_note_mint,
            loan_account,
            deposit_account,
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::MarginBorrow { amount }.data(),
            accounts,
        }
    }
    pub fn margin_repay(
        &self,
        margin_account: Pubkey,
        deposit_account: Pubkey,
        loan_account: Pubkey,
        amount: Amount,
    ) -> Instruction {
        let accounts = ix_accounts::MarginRepay {
            margin_account,
            margin_pool: self.address,
            loan_note_mint: self.loan_note_mint,
            deposit_note_mint: self.deposit_note_mint,
            loan_account,
            deposit_account,
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::MarginRepay { amount }.data(),
            accounts,
        }
    }
    pub fn margin_withdraw(
        &self,
        margin_account: Pubkey,
        source: Pubkey,
        destination: Pubkey,
        amount: Amount,
    ) -> Instruction {
        let accounts = ix_accounts::MarginWithdraw {
            margin_account,
            margin_pool: self.address,
            vault: self.vault,
            deposit_note_mint: self.deposit_note_mint,
            source,
            destination,
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::MarginWithdraw { amount }.data(),
            accounts,
        }
    }
    pub fn margin_refresh_position(&self, margin_account: Pubkey, oracle: Pubkey) -> Instruction {
        let accounts = ix_accounts::MarginRefreshPosition {
            margin_account,
            margin_pool: self.address,
            token_price_oracle: oracle,
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::MarginRefreshPosition {}.data(),
            accounts,
        }
    }
    pub fn collect(&self, fee_destination: Pubkey) -> Instruction {
        let accounts = ix_accounts::Collect {
            margin_pool: self.address,
            vault: self.vault,
            fee_destination,
            deposit_note_mint: self.deposit_note_mint,
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_pool::ID,
            data: ix_data::Collect.data(),
            accounts,
        }
    }
}