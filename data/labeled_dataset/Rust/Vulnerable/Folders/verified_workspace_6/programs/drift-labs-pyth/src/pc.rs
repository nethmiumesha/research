use crate::*;
use anchor_lang::prelude::AccountInfo;
use bytemuck::{cast_slice_mut, from_bytes_mut, try_cast_slice_mut, Pod, Zeroable};
use std::cell::RefMut;
#[derive(Default, Copy, Clone)]
#[repr(C)]
pub struct AccKey {
    pub val: [u8; 32],
}
#[derive(Copy, Clone)]
#[repr(C)]
#[allow(dead_code)]
pub enum PriceStatus {
    Unknown,
    Trading,
    Halted,
    Auction,
}
impl Default for PriceStatus {
    fn default() -> Self {
        PriceStatus::Trading
    }
}
#[derive(Copy, Clone)]
#[repr(C)]
pub enum CorpAction {
    NoCorpAct,
}
impl Default for CorpAction {
    fn default() -> Self {
        CorpAction::NoCorpAct
    }
}
#[derive(Default, Copy, Clone)]
#[repr(C)]
pub struct PriceInfo {
    pub price: i64,
    pub conf: u64,
    pub status: PriceStatus,
    pub corp_act: CorpAction,
    pub pub_slot: u64,
}
#[derive(Default, Copy, Clone)]
#[repr(C)]
pub struct PriceComp {
    publisher: AccKey,
    agg: PriceInfo,
    latest: PriceInfo,
}
#[derive(Copy, Clone)]
#[repr(C)]
#[allow(dead_code)]
pub enum PriceType {
    Unknown,
    Price,
    Twap,
    Volatility,
}
impl Default for PriceType {
    fn default() -> Self {
        PriceType::Price
    }
}
#[derive(Default, Copy, Clone)]
#[repr(C)]
pub struct Price {
    pub magic: u32,
    pub ver: u32,
    pub atype: u32,
    pub size: u32,
    pub ptype: PriceType,
    pub expo: i32,
    pub num: u32,
    pub unused: u32,
    pub curr_slot: u64,
    pub valid_slot: u64,
    pub twap: i64,
    pub avol: u64,
    pub drv0: i64,
    pub drv1: i64,
    pub drv2: i64,
    pub drv3: i64,
    pub drv4: i64,
    pub drv5: i64,
    pub prod: AccKey,
    pub next: AccKey,
    pub agg_pub: AccKey,
    pub agg: PriceInfo,
    pub comp: [PriceComp; 32],
}
impl Price {
    #[inline]
    pub fn load<'a>(price_feed: &'a AccountInfo) -> Result<RefMut<'a, Price>> {
        let account_data = RefMut::map(price_feed.try_borrow_mut_data().unwrap(), |data| *data);
        let state = RefMut::map(account_data, |data| {
            from_bytes_mut(cast_slice_mut::<u8, u8>(try_cast_slice_mut(data).unwrap()))
        });
        Ok(state)
    }
}
#[cfg(target_endian = "little")]
unsafe impl Zeroable for Price {}
#[cfg(target_endian = "little")]
unsafe impl Pod for Price {}