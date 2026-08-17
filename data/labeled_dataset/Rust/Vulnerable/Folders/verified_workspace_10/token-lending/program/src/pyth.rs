#![allow(missing_docs)]
use bytemuck::{
    cast_slice, cast_slice_mut, from_bytes, from_bytes_mut, try_cast_slice, try_cast_slice_mut,
    Pod, PodCastError, Zeroable,
};
use std::mem::size_of;
pub const MAGIC: u32 = 0xa1b2c3d4;
pub const VERSION_2: u32 = 2;
pub const VERSION: u32 = VERSION_2;
pub const MAP_TABLE_SIZE: usize = 640;
pub const PROD_ACCT_SIZE: usize = 512;
pub const PROD_HDR_SIZE: usize = 48;
pub const PROD_ATTR_SIZE: usize = PROD_ACCT_SIZE - PROD_HDR_SIZE;
#[derive(Copy, Clone)]
#[repr(C)]
pub struct AccKey {
    pub val: [u8; 32],
}
#[derive(PartialEq, Copy, Clone)]
#[repr(u32)]
pub enum AccountType {
    Unknown,
    Mapping,
    Product,
    Price,
}
#[derive(PartialEq, Copy, Clone)]
#[repr(u32)]
pub enum PriceStatus {
    Unknown,
    Trading,
    Halted,
    Auction,
}
#[derive(PartialEq, Copy, Clone)]
#[repr(u32)]
pub enum CorpAction {
    NoCorpAct,
}
#[derive(Copy, Clone)]
#[repr(C)]
pub struct PriceInfo {
    pub price: i64,
    pub conf: u64,
    pub status: PriceStatus,
    pub corp_act: CorpAction,
    pub pub_slot: u64,
}
#[derive(Copy, Clone)]
#[repr(C)]
pub struct PriceComp {
    publisher: AccKey,
    agg: PriceInfo,
    latest: PriceInfo,
}
#[derive(PartialEq, Copy, Clone)]
#[repr(u32)]
pub enum PriceType {
    Unknown,
    Price,
}
#[derive(Copy, Clone)]
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
#[cfg(target_endian = "little")]
unsafe impl Zeroable for Price {}
#[cfg(target_endian = "little")]
unsafe impl Pod for Price {}
#[derive(Copy, Clone)]
#[repr(C)]
pub struct Product {
    pub magic: u32,
    pub ver: u32,
    pub atype: u32,
    pub size: u32,
    pub px_acc: AccKey,
    pub attr: [u8; PROD_ATTR_SIZE],
}
#[cfg(target_endian = "little")]
unsafe impl Zeroable for Product {}
#[cfg(target_endian = "little")]
unsafe impl Pod for Product {}
pub fn load<T: Pod>(data: &[u8]) -> Result<&T, PodCastError> {
    let size = size_of::<T>();
    Ok(from_bytes(cast_slice::<u8, u8>(try_cast_slice(
        &data[0..size],
    )?)))
}
pub fn load_mut<T: Pod>(data: &mut [u8]) -> Result<&mut T, PodCastError> {
    let size = size_of::<T>();
    Ok(from_bytes_mut(cast_slice_mut::<u8, u8>(
        try_cast_slice_mut(&mut data[0..size])?,
    )))
}