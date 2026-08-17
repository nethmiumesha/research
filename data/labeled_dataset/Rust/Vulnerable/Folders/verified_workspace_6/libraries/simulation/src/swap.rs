use std::sync::Arc;
use anchor_lang::prelude::Pubkey;
use anyhow::Error;
use jet_solana_rpc_api::SolanaRpcClient;
use solana_sdk::{program_pack::Pack, signer::Signer, system_instruction};
use spl_token_swap::curve::{
    base::{CurveType, SwapCurve},
    constant_product::ConstantProductCurve,
    fees::Fees,
};
use crate::tokens::TokenManager;
pub struct SwapPool {
    pub pool: Pubkey,
    pub pool_authority: Pubkey,
    pub mint_a: Pubkey,
    pub mint_b: Pubkey,
    pub token_a: Pubkey,
    pub token_b: Pubkey,
    pub pool_mint: Pubkey,
    pub fee_account: Pubkey,
}
impl SwapPool {
    pub async fn configure(
        rpc: &Arc<dyn SolanaRpcClient>,
        mint_a: &Pubkey,
        mint_b: &Pubkey,
        a_amount: u64,
        b_amount: u64,
    ) -> Result<Self, Error> {
        let token_manager = TokenManager::new(rpc.clone());
        let keypair = crate::generate_keypair();
        let space = spl_token_swap::state::SwapV1::LEN + 1;
        let rent_lamports = rpc.get_minimum_balance_for_rent_exemption(space).await?;
        let ix_pool_state_account = system_instruction::create_account(
            &rpc.payer().pubkey(),
            &keypair.pubkey(),
            rent_lamports,
            space as u64,
            &spl_token_swap::ID,
        );
        let (pool_authority, pool_nonce) =
            Pubkey::find_program_address(&[keypair.pubkey().as_ref()], &spl_token_swap::ID);
        let token_a = token_manager
            .create_account_funded(mint_a, &pool_authority, a_amount)
            .await?;
        let token_b = token_manager
            .create_account_funded(mint_b, &pool_authority, b_amount)
            .await?;
        let pool_mint = token_manager
            .create_token(6, Some(&pool_authority), None)
            .await?;
        let token_fee = token_manager
            .create_account(&pool_mint, &rpc.payer().pubkey())
            .await?;
        let token_recipient = token_manager
            .create_account(&pool_mint, &rpc.payer().pubkey())
            .await?;
        let ix_init = spl_token_swap::instruction::initialize(
            &spl_token_swap::id(),
            &spl_token::id(),
            &keypair.pubkey(),
            &pool_authority,
            &token_a,
            &token_b,
            &pool_mint,
            &token_fee,
            &token_recipient,
            pool_nonce,
            Fees {
                trade_fee_numerator: 1,
                trade_fee_denominator: 40,
                owner_trade_fee_numerator: 2,
                owner_trade_fee_denominator: 50,
                owner_withdraw_fee_numerator: 4,
                owner_withdraw_fee_denominator: 100,
                host_fee_numerator: 10,
                host_fee_denominator: 100,
            },
            SwapCurve {
                curve_type: CurveType::ConstantProduct,
                calculator: Box::new(ConstantProductCurve),
            },
        )?;
        let transaction = rpc
            .create_transaction(&[&keypair], &[ix_pool_state_account, ix_init])
            .await?;
        rpc.send_and_confirm_transaction(&transaction).await?;
        Ok(Self {
            pool: keypair.pubkey(),
            pool_authority,
            mint_a: *mint_a,
            mint_b: *mint_b,
            token_a,
            token_b,
            pool_mint,
            fee_account: token_fee,
        })
    }
}