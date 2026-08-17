use solana_sdk::instruction::Instruction;
use solana_sdk::pubkey::Pubkey;
use anchor_lang::{Id, InstructionData, ToAccountMetas};
use anchor_spl::token::Token;
use jet_margin_swap::accounts as ix_accounts;
use jet_margin_swap::instruction as ix_data;
use crate::ix_builder::MarginPoolIxBuilder;
pub struct MarginSwapIxBuilder {
    pub token_a: Pubkey,
    pub token_b: Pubkey,
    pub swap_pool: Pubkey,
    pub authority: Pubkey,
    pub pool_mint: Pubkey,
    pub fee_account: Pubkey,
}
impl MarginSwapIxBuilder {
    pub fn new(
        token_a: Pubkey,
        token_b: Pubkey,
        swap_pool: Pubkey,
        authority: Pubkey,
        pool_mint: Pubkey,
        fee_account: Pubkey,
    ) -> Self {
        Self {
            token_a,
            token_b,
            swap_pool,
            authority,
            pool_mint,
            fee_account,
        }
    }
    #[allow(clippy::too_many_arguments)]
    pub fn swap(
        &self,
        margin_account: Pubkey,
        transit_src_account: Pubkey,
        transit_dst_account: Pubkey,
        source_margin_position: Pubkey,
        destination_margin_position: Pubkey,
        source_token_account: Pubkey,
        destination_token_account: Pubkey,
        swap_program: Pubkey,
        source_pool: &MarginPoolIxBuilder,
        destination_pool: &MarginPoolIxBuilder,
        amount_in: u64,
        minimum_amount_out: u64,
    ) -> Instruction {
        let accounts = ix_accounts::MarginSplSwap {
            margin_account,
            source_account: source_margin_position,
            destination_account: destination_margin_position,
            transit_source_account: transit_src_account,
            transit_destination_account: transit_dst_account,
            swap_info: ix_accounts::SwapInfo {
                swap_pool: self.swap_pool,
                authority: self.authority,
                vault_into: source_token_account,
                vault_from: destination_token_account,
                token_mint: self.pool_mint,
                fee_account: self.fee_account,
                swap_program,
            },
            source_margin_pool: ix_accounts::MarginPoolInfo {
                margin_pool: source_pool.address,
                vault: source_pool.vault,
                deposit_note_mint: source_pool.deposit_note_mint,
            },
            destination_margin_pool: ix_accounts::MarginPoolInfo {
                margin_pool: destination_pool.address,
                vault: destination_pool.vault,
                deposit_note_mint: destination_pool.deposit_note_mint,
            },
            margin_pool_program: jet_margin_pool::id(),
            token_program: Token::id(),
        }
        .to_account_metas(None);
        Instruction {
            program_id: jet_margin_swap::id(),
            data: ix_data::MarginSwap {
                amount_in,
                minimum_amount_out,
            }
            .data(),
            accounts,
        }
    }
}