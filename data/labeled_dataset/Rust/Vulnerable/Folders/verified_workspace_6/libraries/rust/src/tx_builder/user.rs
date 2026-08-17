#![allow(unused)]
use std::sync::Arc;
use jet_metadata::{PositionTokenMetadata, TokenMetadata};
use anyhow::{bail, Result};
use solana_sdk::instruction::Instruction;
use solana_sdk::pubkey::Pubkey;
use solana_sdk::signature::Keypair;
use solana_sdk::signer::Signer;
use solana_sdk::transaction::Transaction;
use anchor_lang::AccountDeserialize;
use jet_margin::{MarginAccount, PositionKind};
use jet_margin_pool::Amount;
use jet_solana_rpc_api::SolanaRpcClient;
use crate::ix_builder::*;
pub struct MarginTxBuilder {
    rpc: Arc<dyn SolanaRpcClient>,
    ix: MarginIxBuilder,
    signer: Option<Keypair>,
    is_liquidator: bool,
}
impl MarginTxBuilder {
    pub fn new(
        rpc: Arc<dyn SolanaRpcClient>,
        signer: Option<Keypair>,
        owner: Pubkey,
        seed: u16,
        is_liquidator: bool,
    ) -> MarginTxBuilder {
        let ix = MarginIxBuilder::new_with_payer(owner, seed, rpc.payer().pubkey());
        Self {
            rpc,
            ix,
            signer,
            is_liquidator,
        }
    }
    async fn create_transaction(&self, instructions: &[Instruction]) -> Result<Transaction> {
        let signers = self.signer.as_ref().map(|s| vec![s]).unwrap_or_default();
        self.rpc.create_transaction(&signers, instructions).await
    }
    pub fn signer(&self) -> Pubkey {
        self.signer.as_ref().unwrap().pubkey()
    }
    pub fn owner(&self) -> &Pubkey {
        &self.ix.owner
    }
    pub fn address(&self) -> &Pubkey {
        &self.ix.address
    }
    pub async fn create_account(&self) -> Result<Transaction> {
        self.create_transaction(&[self.ix.create_account()]).await
    }
    pub async fn close_account(&self) -> Result<Transaction> {
        self.create_transaction(&[self.ix.close_account()]).await
    }
    pub async fn close_token_positions(&self, token_mint: &Pubkey) -> Result<Transaction> {
        let pool = MarginPoolIxBuilder::new(*token_mint);
        let (deposit_account, _) = self.ix.get_token_account_address(&pool.deposit_note_mint);
        let (loan_account, _) = self.ix.get_token_account_address(&pool.loan_note_mint);
        let instructions = vec![
            self.ix
                .close_position(pool.deposit_note_mint, deposit_account),
            self.ix.close_position(pool.loan_note_mint, loan_account),
        ];
        self.create_transaction(&instructions).await
    }
    pub async fn close_token_position(
        &self,
        token_mint: &Pubkey,
        kind: PositionKind,
    ) -> Result<Transaction> {
        let pool = MarginPoolIxBuilder::new(*token_mint);
        let ((account, _), mint) = match kind {
            PositionKind::NoValue | PositionKind::Deposit => (
                self.ix.get_token_account_address(&pool.deposit_note_mint),
                pool.deposit_note_mint,
            ),
            PositionKind::Claim => (
                self.ix.get_token_account_address(&pool.loan_note_mint),
                pool.loan_note_mint,
            ),
        };
        self.create_transaction(&[self.ix.close_position(mint, account)])
            .await
    }
    pub async fn close_empty_positions(&self) -> Result<Transaction> {
        let to_close = self
            .get_account_state()
            .await?
            .positions()
            .filter(|p| p.balance == 0)
            .map(|p| self.ix.close_position(p.token, p.address))
            .collect::<Vec<_>>();
        self.create_transaction(&to_close).await
    }
    pub async fn deposit(
        &self,
        token_mint: &Pubkey,
        source: &Pubkey,
        amount: u64,
    ) -> Result<Transaction> {
        let mut instructions = vec![];
        let pool = MarginPoolIxBuilder::new(*token_mint);
        let position = self
            .get_or_create_position(&mut instructions, &pool.deposit_note_mint)
            .await?;
        instructions.push(pool.deposit(self.ix.owner, *source, position, amount));
        instructions.push(self.ix.update_position_balance(position));
        self.create_transaction(&instructions).await
    }
    pub async fn borrow(&self, token_mint: &Pubkey, amount: u64) -> Result<Transaction> {
        let mut instructions = vec![];
        let pool = MarginPoolIxBuilder::new(*token_mint);
        let token_metadata = self.get_token_metadata(token_mint).await?;
        let deposit_position = self
            .get_or_create_position(&mut instructions, &pool.deposit_note_mint)
            .await?;
        let loan_position = self
            .get_or_create_position(&mut instructions, &pool.loan_note_mint)
            .await?;
        let inner_refresh_loan_ix =
            pool.margin_refresh_position(self.ix.address, token_metadata.pyth_price);
        instructions.push(self.adapter_invoke_ix(inner_refresh_loan_ix));
        let inner_borrow_ix =
            pool.margin_borrow(self.ix.address, deposit_position, loan_position, amount);
        instructions.push(self.adapter_invoke_ix(inner_borrow_ix));
        self.create_transaction(&instructions).await
    }
    pub async fn repay(&self, token_mint: &Pubkey, amount: Amount) -> Result<Transaction> {
        let mut instructions = vec![];
        let pool = MarginPoolIxBuilder::new(*token_mint);
        let deposit_position = self
            .get_or_create_position(&mut instructions, &pool.deposit_note_mint)
            .await?;
        let loan_position = self
            .get_or_create_position(&mut instructions, &pool.loan_note_mint)
            .await?;
        let inner_repay_ix =
            pool.margin_repay(self.ix.address, deposit_position, loan_position, amount);
        instructions.push(self.adapter_invoke_ix(inner_repay_ix));
        self.create_transaction(&instructions).await
    }
    pub async fn withdraw(
        &self,
        token_mint: &Pubkey,
        destination: &Pubkey,
        amount: Amount,
    ) -> Result<Transaction> {
        let mut instructions = vec![];
        let pool = MarginPoolIxBuilder::new(*token_mint);
        let deposit_position = self
            .get_or_create_position(&mut instructions, &pool.deposit_note_mint)
            .await?;
        let inner_withdraw_ix =
            pool.margin_withdraw(self.ix.address, deposit_position, *destination, amount);
        instructions.push(self.adapter_invoke_ix(inner_withdraw_ix));
        self.create_transaction(&instructions).await
    }
    #[allow(clippy::too_many_arguments)]
    pub async fn swap(
        &self,
        source_token_mint: &Pubkey,
        destination_token_mint: &Pubkey,
        transit_source_account: &Pubkey,
        transit_destination_account: &Pubkey,
        swap_pool: &Pubkey,
        pool_mint: &Pubkey,
        fee_account: &Pubkey,
        source_token_account: &Pubkey,
        destination_token_account: &Pubkey,
        swap_program: &Pubkey,
        amount_in: Amount,
        minimum_amount_out: Amount,
    ) -> Result<Transaction> {
        let mut instructions = vec![];
        let source_pool = MarginPoolIxBuilder::new(*source_token_mint);
        let destination_pool = MarginPoolIxBuilder::new(*destination_token_mint);
        let source_position = self
            .get_or_create_position(&mut instructions, &source_pool.deposit_note_mint)
            .await?;
        let destination_position = self
            .get_or_create_position(&mut instructions, &destination_pool.deposit_note_mint)
            .await?;
        let (swap_authority, _) =
            Pubkey::find_program_address(&[swap_pool.as_ref()], &spl_token_swap::id());
        let swap_pool = MarginSwapIxBuilder::new(
            *source_token_mint,
            *destination_token_mint,
            *swap_pool,
            swap_authority,
            *pool_mint,
            *fee_account,
        );
        let inner_swap_ix = swap_pool.swap(
            *self.address(),
            *transit_source_account,
            *transit_destination_account,
            source_position,
            destination_position,
            *source_token_account,
            *destination_token_account,
            *swap_program,
            &source_pool,
            &destination_pool,
            amount_in.value,
            minimum_amount_out.value,
        );
        instructions.push(self.adapter_invoke_ix(inner_swap_ix));
        self.create_transaction(&instructions).await
    }
    pub async fn liquidate_begin(&self) -> Result<Transaction> {
        assert!(self.is_liquidator);
        self.create_transaction(&[self
            .ix
            .liquidate_begin(self.signer.as_ref().unwrap().pubkey())])
            .await
    }
    pub async fn liquidate_end(&self, original_liquidator: Option<Pubkey>) -> Result<Transaction> {
        let self_key = self
            .signer
            .as_ref()
            .map(|s| s.pubkey())
            .unwrap_or(*self.owner());
        self.create_transaction(&[self.ix.liquidate_end(self_key, original_liquidator)])
            .await
    }
    pub async fn verify_healthy(&self) -> Result<Transaction> {
        let ix = self.ix.verify_healthy();
        Ok(Transaction::new_with_payer(&[ix], None))
    }
    pub async fn refresh_pool_position(&self, token_mint: &Pubkey) -> Result<Transaction> {
        let metadata = self.get_token_metadata(token_mint).await?;
        let ix_builder = MarginPoolIxBuilder::new(*token_mint);
        let ix = self.ix.adapter_invoke(
            ix_builder.margin_refresh_position(self.ix.address, metadata.pyth_price),
        );
        self.create_transaction(&[ix]).await
    }
    pub async fn refresh_all_pool_positions(&self) -> Result<Vec<Transaction>> {
        let state = self.get_account_state().await?;
        let mut instructions = vec![];
        for position in state.positions() {
            let p_metadata = self.get_position_metadata(&position.token).await?;
            let t_metadata = self
                .get_token_metadata(&p_metadata.underlying_token_mint)
                .await?;
            let ix_builder = MarginPoolIxBuilder::new(p_metadata.underlying_token_mint);
            let ix = self.ix.adapter_invoke(
                ix_builder.margin_refresh_position(self.ix.address, t_metadata.pyth_price),
            );
            instructions.push(ix);
        }
        futures::future::join_all(instructions.chunks(12).map(|c| self.create_transaction(c)))
            .await
            .into_iter()
            .collect()
    }
    async fn get_token_metadata(&self, token_mint: &Pubkey) -> Result<TokenMetadata> {
        let (md_address, _) =
            Pubkey::find_program_address(&[token_mint.as_ref()], &jet_metadata::ID);
        let account_data = self.rpc.get_account(&md_address).await?;
        match account_data {
            None => bail!("no metadata {} found for token {}", md_address, token_mint),
            Some(account) => Ok(TokenMetadata::try_deserialize(&mut &account.data[..])?),
        }
    }
    async fn get_position_metadata(
        &self,
        position_token_mint: &Pubkey,
    ) -> Result<PositionTokenMetadata> {
        let (md_address, _) =
            Pubkey::find_program_address(&[position_token_mint.as_ref()], &jet_metadata::ID);
        let account_data = self.rpc.get_account(&md_address).await?;
        match account_data {
            None => bail!(
                "no metadata {} found for position token {}",
                md_address,
                position_token_mint
            ),
            Some(account) => Ok(PositionTokenMetadata::try_deserialize(
                &mut &account.data[..],
            )?),
        }
    }
    async fn get_or_create_position(
        &self,
        instructions: &mut Vec<Instruction>,
        token_mint: &Pubkey,
    ) -> Result<Pubkey> {
        let state = self.get_account_state().await?;
        let (address, ix_register) = self.ix.register_position(*token_mint);
        if !state.positions().any(|p| p.token == *token_mint) {
            instructions.push(ix_register);
        }
        Ok(address)
    }
    async fn get_account_state(&self) -> Result<Box<MarginAccount>> {
        let account_data = self.rpc.get_account(&self.ix.address).await?;
        match account_data {
            None => bail!(
                "no account state found for account {} belonging to {}",
                self.ix.owner,
                self.ix.address
            ),
            Some(account) => Ok(Box::new(MarginAccount::try_deserialize(
                &mut &account.data[..],
            )?)),
        }
    }
    fn adapter_invoke_ix(&self, inner: Instruction) -> Instruction {
        match self.is_liquidator {
            true => self
                .ix
                .liquidator_invoke(inner, &self.signer.as_ref().unwrap().pubkey()),
            false => self.ix.adapter_invoke(inner),
        }
    }
}