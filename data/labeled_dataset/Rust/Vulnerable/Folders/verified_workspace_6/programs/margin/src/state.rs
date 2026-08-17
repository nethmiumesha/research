use anchor_lang::prelude::*;
use bytemuck::{Contiguous, Pod, Zeroable};
#[cfg(any(test, feature = "cli"))]
use serde::ser::{Serialize, SerializeStruct, Serializer};
use crate::{ErrorCode, MAX_PRICE_QUOTE_AGE, MIN_COLLATERAL_RATIO};
use jet_proto_math::Number128;
use jet_proto_proc_macros::assert_size;
const POS_PRICE_VALID: u8 = 1;
#[account(zero_copy)]
#[repr(C)]
#[cfg_attr(not(target_arch = "bpf"), repr(align(8)))]
pub struct MarginAccount {
    pub version: u8,
    pub bump_seed: [u8; 1],
    pub user_seed: [u8; 2],
    pub reserved0: [u8; 4],
    pub owner: Pubkey,
    pub liquidation: Pubkey,
    pub liquidator: Pubkey,
    pub positions: [u8; 7432],
}
#[cfg(any(test, feature = "cli"))]
impl Serialize for MarginAccount {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut s = serializer.serialize_struct("MarginAccount", 5)?;
        s.serialize_field("version", &self.version)?;
        s.serialize_field("owner", &self.owner.to_string())?;
        s.serialize_field("liquidation", &self.liquidation.to_string())?;
        s.serialize_field("liquidator", &self.liquidator.to_string())?;
        s.serialize_field("positions", &self.positions().collect::<Vec<_>>())?;
        s.end()
    }
}
impl std::fmt::Debug for MarginAccount {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::result::Result<(), std::fmt::Error> {
        let mut acc = f.debug_struct("MarginAccount");
        acc.field("version", &self.version)
            .field("bump_seed", &self.bump_seed)
            .field("user_seed", &self.user_seed)
            .field("reserved0", &self.reserved0)
            .field("owner", &self.owner)
            .field("liquidation", &self.liquidation)
            .field("liquidator", &self.liquidator);
        if self.positions().next().is_some() {
            acc.field("positions", &self.positions().collect::<Vec<_>>());
        } else {
            acc.field("positions", &Vec::<AccountPosition>::new());
        }
        acc.finish()
    }
}
impl MarginAccount {
    pub fn start_liquidation(&mut self, liquidation: Pubkey, liquidator: Pubkey) {
        self.liquidation = liquidation;
        self.liquidator = liquidator;
    }
    pub fn end_liquidation(&mut self) {
        self.liquidation = Pubkey::default();
        self.liquidator = Pubkey::default();
    }
    pub fn verify_not_liquidating(&self) -> Result<()> {
        if self.liquidation != Pubkey::default() {
            msg!("account is being liquidated");
            Err(ErrorCode::Liquidating.into())
        } else {
            Ok(())
        }
    }
    pub fn signer_seeds(&self) -> [&[u8]; 3] {
        [
            self.owner.as_ref(),
            self.user_seed.as_ref(),
            self.bump_seed.as_ref(),
        ]
    }
    pub fn initialize(&mut self, owner: Pubkey, seed: u16, bump_seed: u8) {
        self.owner = owner;
        self.bump_seed = [bump_seed];
        self.user_seed = seed.to_le_bytes();
        self.liquidator = Pubkey::default();
    }
    pub fn positions(&self) -> impl Iterator<Item = &AccountPosition> {
        self.position_list()
            .positions
            .iter()
            .filter(|p| p.address != Pubkey::default())
    }
    #[allow(clippy::too_many_arguments)]
    pub fn register_position(
        &mut self,
        token: Pubkey,
        decimals: u8,
        address: Pubkey,
        adapter: Pubkey,
        kind: PositionKind,
        collateral_weight: u16,
        collateral_max_staleness: u64,
    ) -> Result<()> {
        let free_position = self.position_list_mut().add(token)?;
        free_position.exponent = -(decimals as i16);
        free_position.address = address;
        free_position.adapter = adapter;
        free_position.kind = kind.into_integer();
        free_position.balance = 0;
        free_position.collateral_weight = collateral_weight;
        free_position.collateral_max_staleness = collateral_max_staleness;
        Ok(())
    }
    pub fn unregister_position(&mut self, mint: &Pubkey, account: &Pubkey) -> Result<()> {
        let removed = self.position_list_mut().remove(mint, account)?;
        if removed.balance != 0 {
            return err!(ErrorCode::CloseNonZeroPosition);
        }
        Ok(())
    }
    pub fn set_position_balance(
        &mut self,
        mint: &Pubkey,
        account: &Pubkey,
        balance: u64,
    ) -> Result<()> {
        let position = self.position_list_mut().get_mut(mint)?;
        if position.address != *account {
            return err!(ErrorCode::PositionNotOwned);
        }
        position.set_balance(balance);
        Ok(())
    }
    pub fn set_position_price(
        &mut self,
        mint: &Pubkey,
        adapter: &Pubkey,
        price: &PriceInfo,
    ) -> Result<()> {
        let position = self.position_list_mut().get_mut(mint)?;
        position.set_price(adapter, price)
    }
    pub fn verify_healthy_positions(&self) -> Result<()> {
        let info = self.valuation()?;
        let min_ratio = Number128::from_bps(MIN_COLLATERAL_RATIO);
        match info.c_ratio() {
            Some(c_ratio) if c_ratio < min_ratio => {
                msg!("Account unhealty. C-ratio: {}", c_ratio.to_string());
                err!(ErrorCode::Unhealthy)
            }
            _ => Ok(()),
        }
    }
    pub fn verify_unhealthy_positions(&self) -> Result<()> {
        let info = self.valuation()?;
        let min_ratio = Number128::from_bps(MIN_COLLATERAL_RATIO);
        if info.stale_collateral > Number128::ZERO {
            for (position_token, error) in info.stale_collateral_list {
                msg!("stale position {}: {}", position_token, error)
            }
            return Err(error!(ErrorCode::StalePositions));
        }
        match info.c_ratio() {
            Some(c_ratio) if c_ratio < min_ratio => Ok(()),
            _ => Err(error!(ErrorCode::Healthy)),
        }
    }
    pub fn has_authority(&self, authority: Pubkey) -> bool {
        authority == self.owner || authority == self.liquidator
    }
    pub fn valuation(&self) -> Result<Valuation> {
        let timestamp = crate::util::get_timestamp();
        let mut fresh_collateral = Number128::ZERO;
        let mut stale_collateral = Number128::ZERO;
        let mut claims = Number128::ZERO;
        let mut stale_collateral_list = vec![];
        for position in self.positions() {
            let kind = PositionKind::from_integer(position.kind).unwrap();
            let stale_reason = {
                let balance_age = timestamp - position.balance_timestamp;
                let price_quote_age = timestamp - position.price.timestamp;
                if position.price.is_valid != POS_PRICE_VALID {
                    Some(ErrorCode::InvalidPrice)
                } else if position.collateral_max_staleness > 0
                    && balance_age > position.collateral_max_staleness
                {
                    Some(ErrorCode::OutdatedBalance)
                } else if price_quote_age > MAX_PRICE_QUOTE_AGE {
                    Some(ErrorCode::OutdatedPrice)
                } else {
                    None
                }
            };
            match (kind, stale_reason) {
                (PositionKind::NoValue, _) => (),
                (PositionKind::Claim, None) => claims += position.value(),
                (PositionKind::Claim, Some(error)) => return Err(error!(error)),
                (PositionKind::Deposit, None) => fresh_collateral += position.collateral_value(),
                (PositionKind::Deposit, Some(e)) => {
                    stale_collateral += position.collateral_value();
                    stale_collateral_list.push((position.token, e));
                }
            }
        }
        Ok(Valuation {
            fresh_collateral,
            stale_collateral,
            stale_collateral_list,
            claims,
        })
    }
    fn position_list(&self) -> &AccountPositionList {
        bytemuck::from_bytes(&self.positions)
    }
    fn position_list_mut(&mut self) -> &mut AccountPositionList {
        bytemuck::from_bytes_mut(&mut self.positions)
    }
}
#[assert_size(24)]
#[derive(
    Pod, Zeroable, AnchorSerialize, AnchorDeserialize, Debug, Default, Clone, Copy, Eq, PartialEq,
)]
#[cfg_attr(
    any(test, feature = "cli"),
    derive(serde::Serialize),
    serde(rename_all = "camelCase")
)]
#[repr(C)]
pub struct PriceInfo {
    pub value: i64,
    pub timestamp: u64,
    pub exponent: i32,
    pub is_valid: u8,
    #[cfg_attr(any(test, feature = "cli"), serde(skip_serializing))]
    pub _reserved: [u8; 3],
}
impl PriceInfo {
    pub fn new_valid(exponent: i32, value: i64, timestamp: u64) -> Self {
        Self {
            value,
            exponent,
            timestamp,
            is_valid: POS_PRICE_VALID,
            _reserved: [0u8; 3],
        }
    }
    pub fn new_invalid() -> Self {
        Self {
            value: 0,
            exponent: 0,
            timestamp: 0,
            is_valid: 0,
            _reserved: [0u8; 3],
        }
    }
}
#[derive(Debug, Clone, Copy, Contiguous, Eq, PartialEq)]
#[repr(u32)]
pub enum PositionKind {
    NoValue,
    Deposit,
    Claim,
}
#[assert_size(192)]
#[derive(AnchorSerialize, AnchorDeserialize, Default, Clone, Copy)]
#[repr(C)]
pub struct AccountPosition {
    pub token: Pubkey,
    pub address: Pubkey,
    pub adapter: Pubkey,
    pub value: [u8; 16],
    pub balance: u64,
    pub balance_timestamp: u64,
    pub price: PriceInfo,
    pub kind: u32,
    pub exponent: i16,
    pub collateral_weight: u16,
    pub collateral_max_staleness: u64,
    _reserved: [u8; 24],
}
impl AccountPosition {
    pub fn calculate_value(&mut self) {
        self.value = (Number128::from_decimal(self.balance, self.exponent)
            * Number128::from_decimal(self.price.value, self.price.exponent))
        .into_bits();
    }
    pub fn value(&self) -> Number128 {
        Number128::from_bits(self.value)
    }
    pub fn collateral_value(&self) -> Number128 {
        Number128::from_bps(self.collateral_weight) * self.value()
    }
    fn set_balance(&mut self, balance: u64) {
        self.balance = balance;
        self.balance_timestamp = crate::util::get_timestamp();
        self.calculate_value();
    }
    fn set_price(&mut self, adapter: &Pubkey, price: &PriceInfo) -> Result<()> {
        if self.adapter != *adapter {
            return err!(ErrorCode::InvalidPriceAdapter);
        }
        self.price = *price;
        self.calculate_value();
        Ok(())
    }
}
impl std::fmt::Debug for AccountPosition {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::result::Result<(), std::fmt::Error> {
        let mut acc = f.debug_struct("AccountPosition");
        acc.field("token", &self.token)
            .field("address", &self.address)
            .field("adapter", &self.adapter)
            .field("value", &self.value().to_string())
            .field("balance", &self.balance)
            .field("balance_timestamp", &self.balance_timestamp)
            .field("price", &self.price)
            .field("kind", &self.kind)
            .field("exponent", &self.exponent)
            .field("collateral_weight", &self.collateral_weight)
            .field("collateral_max_staleness", &self.collateral_max_staleness);
        acc.finish()
    }
}
#[cfg(any(test, feature = "cli"))]
impl Serialize for AccountPosition {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut s = serializer.serialize_struct("AccountPosition", 11)?;
        s.serialize_field("address", &self.address.to_string())?;
        s.serialize_field("token", &self.token.to_string())?;
        s.serialize_field("adapter", &self.adapter.to_string())?;
        s.serialize_field("value", &self.value().to_string())?;
        s.serialize_field("balance", &self.balance)?;
        s.serialize_field("balanceTimestamp", &self.balance_timestamp)?;
        s.serialize_field("price", &self.price)?;
        s.serialize_field("kind", &self.kind)?;
        s.serialize_field("exponent", &self.exponent)?;
        s.serialize_field("collateralWeight", &self.collateral_weight)?;
        s.serialize_field("collateralMaxStaleness", &self.collateral_max_staleness)?;
        s.end()
    }
}
#[assert_size(40)]
#[derive(AnchorSerialize, AnchorDeserialize, Default, Pod, Zeroable, Debug, Clone, Copy)]
#[repr(C)]
pub struct AccountPositionKey {
    mint: Pubkey,
    index: usize,
}
#[assert_size(7432)]
#[derive(AnchorSerialize, AnchorDeserialize, Default, Pod, Zeroable, Debug, Clone, Copy)]
#[repr(C)]
pub struct AccountPositionList {
    pub length: usize,
    pub map: [AccountPositionKey; 32],
    pub positions: [AccountPosition; 32],
}
impl AccountPositionList {
    pub fn add(&mut self, mint: Pubkey) -> Result<&mut AccountPosition> {
        if self.map.iter().any(|p| p.mint == mint) {
            return err!(ErrorCode::PositionAlreadyRegistered);
        }
        let (index, free_position) = self
            .positions
            .iter_mut()
            .enumerate()
            .find(|(_, p)| p.token == Pubkey::default())
            .ok_or_else(|| error!(ErrorCode::MaxPositions))?;
        self.map[self.length] = AccountPositionKey { mint, index };
        self.length += 1;
        (&mut self.map[..self.length]).sort_by_key(|p| p.mint);
        free_position.token = mint;
        Ok(free_position)
    }
    pub fn remove(&mut self, mint: &Pubkey, account: &Pubkey) -> Result<AccountPosition> {
        let map_index = self.get_map_index(mint)?;
        let map = self.map[map_index];
        let position = self.positions[map.index];
        if &position.address != account {
            return err!(ErrorCode::PositionNotOwned);
        }
        let freed_position = bytemuck::bytes_of_mut(&mut self.positions[map.index]);
        freed_position.fill(0);
        (&mut self.map).copy_within(map_index + 1..self.length, map_index);
        self.length -= 1;
        self.map[self.length].mint = Pubkey::default();
        self.map[self.length].index = 0;
        Ok(position)
    }
    pub fn get(&self, mint: &Pubkey) -> Result<&AccountPosition> {
        let key = self.get_key(mint)?;
        let position = &self.positions[key.index];
        Ok(position)
    }
    pub fn get_mut(&mut self, mint: &Pubkey) -> Result<&mut AccountPosition> {
        let key = self.get_key(mint)?;
        let position = &mut self.positions[key.index];
        Ok(position)
    }
    fn get_key(&self, mint: &Pubkey) -> Result<&AccountPositionKey> {
        Ok(&self.map[self.get_map_index(mint)?])
    }
    fn get_map_index(&self, mint: &Pubkey) -> Result<usize> {
        (&self.map[..self.length])
            .binary_search_by_key(mint, |p| p.mint)
            .map_err(|_| error!(ErrorCode::UnknownPosition))
    }
}
unsafe impl Zeroable for AccountPosition {}
unsafe impl Pod for AccountPosition {}
#[account(zero_copy)]
#[derive(Debug)]
pub struct Liquidation {
    pub start_time: i64,
    pub value_change: Number128,
    pub c_ratio_change: Number128,
    pub min_value_change: Number128,
}
impl Default for Liquidation {
    fn default() -> Self {
        Self {
            start_time: Default::default(),
            value_change: Number128::ZERO,
            c_ratio_change: Number128::ZERO,
            min_value_change: Number128::ZERO,
        }
    }
}
#[derive(Debug, Clone)]
pub struct Valuation {
    fresh_collateral: Number128,
    stale_collateral: Number128,
    stale_collateral_list: Vec<(Pubkey, ErrorCode)>,
    claims: Number128,
}
impl Valuation {
    pub fn c_ratio(&self) -> Option<Number128> {
        if self.claims == Number128::ZERO {
            return None;
        }
        Some(self.fresh_collateral / self.claims)
    }
    pub fn net(&self) -> Number128 {
        self.fresh_collateral - self.claims
    }
    pub fn claims(&self) -> Number128 {
        self.claims
    }
    pub fn collateral(&self) -> Number128 {
        self.fresh_collateral
    }
}