use anchor_lang::prelude::*;
use borsh::{BorshDeserialize, BorshSerialize};
use spl_concurrent_merkle_tree::concurrent_merkle_tree::ConcurrentMerkleTree;
use std::mem::size_of;
use crate::error::AccountCompressionError;
pub const CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1: usize = 2 + 54;
#[derive(Debug, Copy, Clone, PartialEq, BorshDeserialize, BorshSerialize)]
#[repr(u8)]
pub enum CompressionAccountType {
    Uninitialized,
    ConcurrentMerkleTree,
}
impl std::fmt::Display for CompressionAccountType {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{:?}", &self)
    }
}
#[cfg(feature = "idl-build")]
impl anchor_lang::IdlBuild for CompressionAccountType {}
#[repr(C)]
#[derive(AnchorDeserialize, AnchorSerialize)]
pub struct ConcurrentMerkleTreeHeader {
    pub account_type: CompressionAccountType,
    pub header: ConcurrentMerkleTreeHeaderData,
}
#[repr(C)]
#[derive(AnchorDeserialize, AnchorSerialize)]
pub struct ConcurrentMerkleTreeHeaderDataV1 {
    max_buffer_size: u32,
    max_depth: u32,
    authority: Pubkey,
    creation_slot: u64,
    is_batch_initialized: bool,
    _padding: [u8; 5],
}
#[repr(C)]
#[derive(AnchorDeserialize, AnchorSerialize)]
pub enum ConcurrentMerkleTreeHeaderData {
    V1(ConcurrentMerkleTreeHeaderDataV1),
}
impl ConcurrentMerkleTreeHeader {
    pub fn initialize(
        &mut self,
        max_depth: u32,
        max_buffer_size: u32,
        authority: &Pubkey,
        creation_slot: u64,
    ) {
        self.account_type = CompressionAccountType::ConcurrentMerkleTree;
        match self.header {
            ConcurrentMerkleTreeHeaderData::V1(ref mut header) => {
                assert_eq!(header.max_buffer_size, 0);
                assert_eq!(header.max_depth, 0);
                header.max_buffer_size = max_buffer_size;
                header.max_depth = max_depth;
                header.authority = *authority;
                header.creation_slot = creation_slot;
            }
        }
    }
    pub fn initialize_batched(
        &mut self,
        max_depth: u32,
        max_buffer_size: u32,
        authority: &Pubkey,
        creation_slot: u64,
    ) {
        self.initialize(max_depth, max_buffer_size, authority, creation_slot);
        match self.header {
            ConcurrentMerkleTreeHeaderData::V1(ref mut header) => {
                header.is_batch_initialized = true;
            }
        }
    }
    pub fn get_max_depth(&self) -> u32 {
        match &self.header {
            ConcurrentMerkleTreeHeaderData::V1(header) => header.max_depth,
        }
    }
    pub fn get_max_buffer_size(&self) -> u32 {
        match &self.header {
            ConcurrentMerkleTreeHeaderData::V1(header) => header.max_buffer_size,
        }
    }
    pub fn get_creation_slot(&self) -> u64 {
        match &self.header {
            ConcurrentMerkleTreeHeaderData::V1(header) => header.creation_slot,
        }
    }
    pub fn get_is_batch_initialized(&self) -> bool {
        match &self.header {
            ConcurrentMerkleTreeHeaderData::V1(header) => header.is_batch_initialized,
        }
    }
    pub fn set_new_authority(&mut self, new_authority: &Pubkey) {
        match self.header {
            ConcurrentMerkleTreeHeaderData::V1(ref mut header) => {
                header.authority = new_authority.clone();
                msg!("Authority transferred to: {:?}", header.authority);
            }
        }
    }
    pub fn assert_valid(&self) -> Result<()> {
        require_eq!(
            self.account_type,
            CompressionAccountType::ConcurrentMerkleTree,
            AccountCompressionError::IncorrectAccountType,
        );
        Ok(())
    }
    pub fn assert_valid_authority(&self, expected_authority: &Pubkey) -> Result<()> {
        self.assert_valid()?;
        match &self.header {
            ConcurrentMerkleTreeHeaderData::V1(header) => {
                require_eq!(
                    header.authority,
                    *expected_authority,
                    AccountCompressionError::IncorrectAuthority,
                );
            }
        }
        Ok(())
    }
    pub fn assert_valid_leaf_index(&self, leaf_index: u32) -> Result<()> {
        if leaf_index >= (1 << self.get_max_depth()) {
            return Err(AccountCompressionError::LeafIndexOutOfBounds.into());
        }
        Ok(())
    }
    pub fn assert_is_batch_initialized(&self) -> Result<()> {
        match &self.header {
            ConcurrentMerkleTreeHeaderData::V1(header) => {
                require!(
                    header.is_batch_initialized,
                    AccountCompressionError::BatchNotInitialized
                );
            }
        }
        Ok(())
    }
}
pub fn merkle_tree_get_size(header: &ConcurrentMerkleTreeHeader) -> Result<usize> {
    match (header.get_max_depth(), header.get_max_buffer_size()) {
        (3, 8) => Ok(size_of::<ConcurrentMerkleTree<3, 8>>()),
        (5, 8) => Ok(size_of::<ConcurrentMerkleTree<5, 8>>()),
        (6, 16) => Ok(size_of::<ConcurrentMerkleTree<6, 16>>()),
        (7, 16) => Ok(size_of::<ConcurrentMerkleTree<7, 16>>()),
        (8, 16) => Ok(size_of::<ConcurrentMerkleTree<8, 16>>()),
        (9, 16) => Ok(size_of::<ConcurrentMerkleTree<9, 16>>()),
        (10, 32) => Ok(size_of::<ConcurrentMerkleTree<10, 32>>()),
        (11, 32) => Ok(size_of::<ConcurrentMerkleTree<11, 32>>()),
        (12, 32) => Ok(size_of::<ConcurrentMerkleTree<12, 32>>()),
        (13, 32) => Ok(size_of::<ConcurrentMerkleTree<13, 32>>()),
        (14, 64) => Ok(size_of::<ConcurrentMerkleTree<14, 64>>()),
        (14, 256) => Ok(size_of::<ConcurrentMerkleTree<14, 256>>()),
        (14, 1024) => Ok(size_of::<ConcurrentMerkleTree<14, 1024>>()),
        (14, 2048) => Ok(size_of::<ConcurrentMerkleTree<14, 2048>>()),
        (15, 64) => Ok(size_of::<ConcurrentMerkleTree<15, 64>>()),
        (16, 64) => Ok(size_of::<ConcurrentMerkleTree<16, 64>>()),
        (17, 64) => Ok(size_of::<ConcurrentMerkleTree<17, 64>>()),
        (18, 64) => Ok(size_of::<ConcurrentMerkleTree<18, 64>>()),
        (19, 64) => Ok(size_of::<ConcurrentMerkleTree<19, 64>>()),
        (20, 64) => Ok(size_of::<ConcurrentMerkleTree<20, 64>>()),
        (20, 256) => Ok(size_of::<ConcurrentMerkleTree<20, 256>>()),
        (20, 1024) => Ok(size_of::<ConcurrentMerkleTree<20, 1024>>()),
        (20, 2048) => Ok(size_of::<ConcurrentMerkleTree<20, 2048>>()),
        (24, 64) => Ok(size_of::<ConcurrentMerkleTree<24, 64>>()),
        (24, 256) => Ok(size_of::<ConcurrentMerkleTree<24, 256>>()),
        (24, 512) => Ok(size_of::<ConcurrentMerkleTree<24, 512>>()),
        (24, 1024) => Ok(size_of::<ConcurrentMerkleTree<24, 1024>>()),
        (24, 2048) => Ok(size_of::<ConcurrentMerkleTree<24, 2048>>()),
        (26, 512) => Ok(size_of::<ConcurrentMerkleTree<26, 512>>()),
        (26, 1024) => Ok(size_of::<ConcurrentMerkleTree<26, 1024>>()),
        (26, 2048) => Ok(size_of::<ConcurrentMerkleTree<26, 2048>>()),
        (30, 512) => Ok(size_of::<ConcurrentMerkleTree<30, 512>>()),
        (30, 1024) => Ok(size_of::<ConcurrentMerkleTree<30, 1024>>()),
        (30, 2048) => Ok(size_of::<ConcurrentMerkleTree<30, 2048>>()),
        _ => {
            msg!(
                "Failed to get size of max depth {} and max buffer size {}",
                header.get_max_depth(),
                header.get_max_buffer_size()
            );
            err!(AccountCompressionError::ConcurrentMerkleTreeConstantsError)
        }
    }
}