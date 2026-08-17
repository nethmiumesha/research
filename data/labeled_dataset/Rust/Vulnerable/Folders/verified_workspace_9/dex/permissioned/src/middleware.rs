use crate::{open_orders_authority, open_orders_init_authority};
use anchor_lang::prelude::*;
use anchor_lang::solana_program::instruction::Instruction;
use anchor_lang::solana_program::system_program;
use anchor_lang::Accounts;
use anchor_spl::{dex, token};
use serum_dex::instruction::*;
use serum_dex::matching::Side;
use serum_dex::state::OpenOrders;
use std::mem::size_of;
pub struct Context<'a, 'info> {
    pub program_id: &'a Pubkey,
    pub dex_program_id: &'a Pubkey,
    pub accounts: Vec<AccountInfo<'info>>,
    pub seeds: Seeds,
    pub pre_instructions: Vec<(Instruction, Vec<AccountInfo<'info>>, Seeds)>,
    pub post_instructions: Vec<(Instruction, Vec<AccountInfo<'info>>, Seeds)>,
    pub post_callbacks: Vec<(PostCallback<'a, 'info>, Vec<AccountInfo<'info>>, Vec<u8>)>,
}
type PostCallback<'a, 'info> = fn(
    &'a Pubkey,
    Vec<AccountInfo<'info>>,
    Vec<u8>,
    Vec<u8>,
) -> ProgramResult;
type Seeds = Vec<Vec<Vec<u8>>>;
impl<'a, 'info> Context<'a, 'info> {
    pub fn new(
        program_id: &'a Pubkey,
        dex_program_id: &'a Pubkey,
        accounts: Vec<AccountInfo<'info>>,
    ) -> Self {
        Self {
            program_id,
            dex_program_id,
            accounts,
            seeds: Vec::new(),
            pre_instructions: Vec::new(),
            post_instructions: Vec::new(),
            post_callbacks: Vec::new(),
        }
    }
}
pub trait MarketMiddleware {
    fn instruction(&mut self, _data: &mut &[u8]) -> ProgramResult {
        Ok(())
    }
    fn init_open_orders(&self, _ctx: &mut Context) -> ProgramResult {
        Ok(())
    }
    fn new_order_v3(&self, _ctx: &mut Context, _ix: &mut NewOrderInstructionV3) -> ProgramResult {
        Ok(())
    }
    fn cancel_order_v2(
        &self,
        _ctx: &mut Context,
        _ix: &mut CancelOrderInstructionV2,
    ) -> ProgramResult {
        Ok(())
    }
    fn cancel_order_by_client_id_v2(
        &self,
        _ctx: &mut Context,
        _client_id: &mut u64,
    ) -> ProgramResult {
        Ok(())
    }
    fn settle_funds(&self, _ctx: &mut Context) -> ProgramResult {
        Ok(())
    }
    fn close_open_orders(&self, _ctx: &mut Context) -> ProgramResult {
        Ok(())
    }
    fn consume_events(&self, _ctx: &mut Context, _limit: &mut u16) -> ProgramResult {
        Ok(())
    }
    fn consume_events_permissioned(&self, _ctx: &mut Context, _limit: &mut u16) -> ProgramResult {
        Ok(())
    }
    fn prune(&self, _ctx: &mut Context, _limit: &mut u16) -> ProgramResult {
        Ok(())
    }
    fn fallback(&self, _ctx: &mut Context) -> ProgramResult {
        Ok(())
    }
}
#[derive(Default)]
pub struct OpenOrdersPda {
    bump: u8,
    bump_init: u8,
}
impl OpenOrdersPda {
    pub fn new() -> Self {
        Self {
            bump: 0,
            bump_init: 0,
        }
    }
    fn prepare_pda<'info>(acc_info: &AccountInfo<'info>) -> AccountInfo<'info> {
        let mut acc_info = acc_info.clone();
        acc_info.is_signer = true;
        acc_info
    }
}
impl MarketMiddleware for OpenOrdersPda {
    fn instruction(&mut self, data: &mut &[u8]) -> ProgramResult {
        let disc = data[0];
        *data = &data[1..];
        if disc == 0 {
            self.bump = data[0];
            self.bump_init = data[1];
            *data = &data[2..];
        }
        Ok(())
    }
    fn init_open_orders<'a, 'info>(&self, ctx: &mut Context<'a, 'info>) -> ProgramResult {
        let market = &ctx.accounts[4];
        let user = &ctx.accounts[3];
        let mut accounts = &ctx.accounts[..];
        InitAccount::try_accounts(ctx.program_id, &mut accounts, &[self.bump, self.bump_init])?;
        ctx.seeds.push(open_orders_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            authority = user.key,
            bump = self.bump
        });
        ctx.seeds.push(open_orders_init_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            bump = self.bump_init
        });
        ctx.accounts = (&ctx.accounts[2..]).to_vec();
        ctx.accounts[1] = Self::prepare_pda(&ctx.accounts[0]);
        ctx.accounts[4].is_signer = true;
        Ok(())
    }
    fn new_order_v3(&self, ctx: &mut Context, ix: &mut NewOrderInstructionV3) -> ProgramResult {
        let user = &ctx.accounts[7];
        if !user.is_signer {
            return Err(ErrorCode::UnauthorizedUser.into());
        }
        let market = &ctx.accounts[0];
        let open_orders = &ctx.accounts[1];
        let token_account_payer = &ctx.accounts[6];
        let pre_instruction = {
            let amount = match ix.side {
                Side::Bid => ix.max_native_pc_qty_including_fees.get(),
                Side::Ask => {
                    let coin_lot_idx = 5 + 43 * 8;
                    let data = market.try_borrow_data()?;
                    let mut coin_lot_array = [0u8; 8];
                    coin_lot_array.copy_from_slice(&data[coin_lot_idx..coin_lot_idx + 8]);
                    let coin_lot_size = u64::from_le_bytes(coin_lot_array);
                    ix.max_coin_qty.get().checked_mul(coin_lot_size).unwrap()
                }
            };
            let ix = spl_token::instruction::approve(
                &spl_token::ID,
                token_account_payer.key,
                open_orders.key,
                user.key,
                &[],
                amount,
            )?;
            let accounts = vec![
                token_account_payer.clone(),
                open_orders.clone(),
                user.clone(),
            ];
            (ix, accounts, Vec::new())
        };
        ctx.pre_instructions.push(pre_instruction);
        let post_instruction = {
            let ix = spl_token::instruction::revoke(
                &spl_token::ID,
                token_account_payer.key,
                user.key,
                &[],
            )?;
            let accounts = vec![token_account_payer.clone(), user.clone()];
            (ix, accounts, Vec::new())
        };
        ctx.post_instructions.push(post_instruction);
        ctx.seeds.push(open_orders_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            authority = user.key
        });
        ctx.accounts[7] = Self::prepare_pda(open_orders);
        Ok(())
    }
    fn cancel_order_v2(
        &self,
        ctx: &mut Context,
        _ix: &mut CancelOrderInstructionV2,
    ) -> ProgramResult {
        let market = &ctx.accounts[0];
        let user = &ctx.accounts[4];
        if !user.is_signer {
            return Err(ErrorCode::UnauthorizedUser.into());
        }
        ctx.seeds.push(open_orders_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            authority = user.key
        });
        ctx.accounts[4] = Self::prepare_pda(&ctx.accounts[3]);
        Ok(())
    }
    fn cancel_order_by_client_id_v2(
        &self,
        ctx: &mut Context,
        _client_id: &mut u64,
    ) -> ProgramResult {
        let market = &ctx.accounts[0];
        let user = &ctx.accounts[4];
        if !user.is_signer {
            return Err(ErrorCode::UnauthorizedUser.into());
        }
        ctx.seeds.push(open_orders_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            authority = user.key
        });
        ctx.accounts[4] = Self::prepare_pda(&ctx.accounts[3]);
        Ok(())
    }
    fn settle_funds(&self, ctx: &mut Context) -> ProgramResult {
        let market = &ctx.accounts[0];
        let user = &ctx.accounts[2];
        if !user.is_signer {
            return Err(ErrorCode::UnauthorizedUser.into());
        }
        ctx.seeds.push(open_orders_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            authority = user.key
        });
        ctx.accounts[2] = Self::prepare_pda(&ctx.accounts[1]);
        Ok(())
    }
    fn close_open_orders(&self, ctx: &mut Context) -> ProgramResult {
        let market = &ctx.accounts[3];
        let user = &ctx.accounts[1];
        if !user.is_signer {
            return Err(ErrorCode::UnauthorizedUser.into());
        }
        ctx.seeds.push(open_orders_authority! {
            program = ctx.program_id,
            dex_program = ctx.dex_program_id,
            market = market.key,
            authority = user.key
        });
        ctx.accounts[1] = Self::prepare_pda(&ctx.accounts[0]);
        Ok(())
    }
    fn prune(&self, ctx: &mut Context, _limit: &mut u16) -> ProgramResult {
        ctx.accounts[5] = ctx.accounts[4].clone();
        Ok(())
    }
}
pub struct Logger;
impl MarketMiddleware for Logger {
    fn init_open_orders(&self, _ctx: &mut Context) -> ProgramResult {
        msg!("proxying open orders");
        Ok(())
    }
    fn new_order_v3(&self, _ctx: &mut Context, ix: &mut NewOrderInstructionV3) -> ProgramResult {
        msg!("proxying new order v3 {:?}", ix);
        Ok(())
    }
    fn cancel_order_v2(
        &self,
        _ctx: &mut Context,
        ix: &mut CancelOrderInstructionV2,
    ) -> ProgramResult {
        msg!("proxying cancel order v2 {:?}", ix);
        Ok(())
    }
    fn cancel_order_by_client_id_v2(
        &self,
        _ctx: &mut Context,
        client_id: &mut u64,
    ) -> ProgramResult {
        msg!("proxying cancel order by client id v2 {:?}", client_id);
        Ok(())
    }
    fn settle_funds(&self, _ctx: &mut Context) -> ProgramResult {
        msg!("proxying settle funds");
        Ok(())
    }
    fn close_open_orders(&self, _ctx: &mut Context) -> ProgramResult {
        msg!("proxying close open orders");
        Ok(())
    }
    fn prune(&self, _ctx: &mut Context, limit: &mut u16) -> ProgramResult {
        msg!("proxying prune {:?}", limit);
        Ok(())
    }
}
pub struct ReferralFees {
    referral: Pubkey,
}
impl ReferralFees {
    pub fn new(referral: Pubkey) -> Self {
        Self { referral }
    }
}
impl MarketMiddleware for ReferralFees {
    fn settle_funds(&self, ctx: &mut Context) -> ProgramResult {
        let referral = token::accessor::authority(&ctx.accounts[9])?;
        require!(referral == self.referral, ErrorCode::InvalidReferral);
        Ok(())
    }
}
#[macro_export]
macro_rules! open_orders_authority {
    (
        program = $program:expr,
        dex_program = $dex_program:expr,
        market = $market:expr,
        authority = $authority:expr,
        bump = $bump:expr
    ) => {
        vec![
            b"open-orders".to_vec(),
            $dex_program.as_ref().to_vec(),
            $market.as_ref().to_vec(),
            $authority.as_ref().to_vec(),
            vec![$bump],
        ]
    };
    (
        program = $program:expr,
        dex_program = $dex_program:expr,
        market = $market:expr,
        authority = $authority:expr
    ) => {
        vec![
            b"open-orders".to_vec(),
            $dex_program.as_ref().to_vec(),
            $market.as_ref().to_vec(),
            $authority.as_ref().to_vec(),
            vec![
                Pubkey::find_program_address(
                    &[
                        b"open-orders".as_ref(),
                        $dex_program.as_ref(),
                        $market.as_ref(),
                        $authority.as_ref(),
                    ],
                    $program,
                )
                .1,
            ],
        ]
    };
}
#[macro_export]
macro_rules! open_orders_init_authority {
    (
        program = $program:expr,
        dex_program = $dex_program:expr,
        market = $market:expr,
        bump = $bump:expr
    ) => {
        vec![
            b"open-orders-init".to_vec(),
            $dex_program.as_ref().to_vec(),
            $market.as_ref().to_vec(),
            vec![$bump],
        ]
    };
}
#[error(offset = 500)]
pub enum ErrorCode {
    #[msg("Program ID does not match the Serum DEX")]
    InvalidDexPid,
    #[msg("Invalid instruction given")]
    InvalidInstruction,
    #[msg("Could not unpack the instruction")]
    CannotUnpack,
    #[msg("Invalid referral address given")]
    InvalidReferral,
    #[msg("The user didn't sign")]
    UnauthorizedUser,
    #[msg("Not enough accounts were provided")]
    NotEnoughAccounts,
    #[msg("Invalid target program ID")]
    InvalidTargetProgram,
}
#[derive(Accounts)]
#[instruction(bump: u8, bump_init: u8)]
pub struct InitAccount<'info> {
    #[account(address = dex::ID)]
    pub dex_program: AccountInfo<'info>,
    #[account(address = system_program::ID)]
    pub system_program: AccountInfo<'info>,
    #[account(
        init,
        seeds = [b"open-orders", dex_program.key.as_ref(), market.key.as_ref(), authority.key.as_ref()],
        bump = bump,
        payer = authority,
        owner = dex::ID,
        space = size_of::<OpenOrders>() + SERUM_PADDING,
    )]
    pub open_orders: AccountInfo<'info>,
    #[account(signer)]
    pub authority: AccountInfo<'info>,
    pub market: AccountInfo<'info>,
    pub rent: Sysvar<'info, Rent>,
    #[account(
        seeds = [b"open-orders-init", dex_program.key.as_ref(), market.key.as_ref()],
        bump = bump_init,
    )]
    pub open_orders_init_authority: AccountInfo<'info>,
}
const SERUM_PADDING: usize = 12;