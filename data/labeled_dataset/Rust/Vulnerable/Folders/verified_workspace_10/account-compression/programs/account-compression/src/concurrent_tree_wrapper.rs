pub use crate::error::AccountCompressionError;
pub use spl_concurrent_merkle_tree::{
    concurrent_merkle_tree::{
        ConcurrentMerkleTree, FillEmptyOrAppendArgs, InitializeWithRootArgs, ProveLeafArgs,
        SetLeafArgs,
    },
    error::ConcurrentMerkleTreeError,
    node::Node,
    node::EMPTY,
};
use {
    crate::{
        events::ChangeLogEvent, macros::*, state::ConcurrentMerkleTreeHeader, zero_copy::ZeroCopy,
    },
    anchor_lang::prelude::*,
};
#[inline(never)]
pub fn merkle_tree_initialize_empty(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &mut [u8],
) -> Result<Box<ChangeLogEvent>> {
    merkle_tree_apply_fn_mut!(header, tree_id, tree_bytes, initialize,)
}
#[inline(never)]
pub fn merkle_tree_initialize_with_root(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &mut [u8],
    args: &InitializeWithRootArgs,
) -> Result<Box<ChangeLogEvent>> {
    merkle_tree_apply_fn_mut!(header, tree_id, tree_bytes, initialize_with_root, args)
}
#[inline(never)]
pub fn merkle_tree_set_leaf(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &mut [u8],
    args: &SetLeafArgs,
) -> Result<Box<ChangeLogEvent>> {
    merkle_tree_apply_fn_mut!(header, tree_id, tree_bytes, set_leaf, args)
}
#[inline(never)]
pub fn merkle_tree_fill_empty_or_append(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &mut [u8],
    args: &FillEmptyOrAppendArgs,
) -> Result<Box<ChangeLogEvent>> {
    merkle_tree_apply_fn_mut!(header, tree_id, tree_bytes, fill_empty_or_append, args)
}
#[inline(never)]
pub fn merkle_tree_prove_leaf(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &[u8],
    args: &ProveLeafArgs,
) -> Result<Box<ChangeLogEvent>> {
    merkle_tree_apply_fn!(header, tree_id, tree_bytes, prove_leaf, args)
}
#[inline(never)]
pub fn merkle_tree_append_leaf(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &mut [u8],
    args: &[u8; 32],
) -> Result<Box<ChangeLogEvent>> {
    merkle_tree_apply_fn_mut!(header, tree_id, tree_bytes, append, *args)
}
pub fn tree_bytes_uninitialized(tree_bytes: &[u8]) -> bool {
    tree_bytes.iter().all(|&x| x == 0)
}
#[inline(never)]
pub fn assert_tree_is_empty(
    header: &ConcurrentMerkleTreeHeader,
    tree_id: Pubkey,
    tree_bytes: &mut [u8],
) -> Result<()> {
    if header.get_is_batch_initialized() && tree_bytes_uninitialized(tree_bytes) {
        return Ok(());
    }
    merkle_tree_apply_fn_mut!(header, tree_id, tree_bytes, prove_tree_is_empty,)?;
    Ok(())
}