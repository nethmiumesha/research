use crate::error::AccountCompressionError;
use crate::events::ChangeLogEvent;
use anchor_lang::prelude::*;
use bytemuck::{cast_slice, cast_slice_mut};
use solana_program::keccak::hashv;
use spl_concurrent_merkle_tree::node::{empty_node_cached, empty_node_cached_mut, Node, EMPTY};
use std::mem::size_of;
const MAX_SUPPORTED_DEPTH: usize = 30;
#[inline(always)]
pub fn check_canopy_bytes(canopy_bytes: &[u8]) -> Result<()> {
    if canopy_bytes.len() % size_of::<Node>() != 0 {
        msg!(
            "Canopy byte length {} is not a multiple of {}",
            canopy_bytes.len(),
            size_of::<Node>()
        );
        err!(AccountCompressionError::CanopyLengthMismatch)
    } else {
        Ok(())
    }
}
#[inline(always)]
fn get_cached_path_length(canopy: &[Node], max_depth: u32) -> Result<u32> {
    let closest_power_of_2 = (canopy.len() + 2) as u32;
    if closest_power_of_2 & (closest_power_of_2 - 1) == 0 {
        if closest_power_of_2 > (1 << (max_depth + 1)) {
            msg!(
                "Canopy size is too large. Size: {}. Max size: {}",
                closest_power_of_2 - 2,
                (1 << (max_depth + 1)) - 2
            );
            return err!(AccountCompressionError::CanopyLengthMismatch);
        }
    } else {
        msg!(
            "Canopy length {} is not 2 less than a power of 2",
            canopy.len()
        );
        return err!(AccountCompressionError::CanopyLengthMismatch);
    }
    Ok(closest_power_of_2.trailing_zeros() - 1)
}
pub fn update_canopy(
    canopy_bytes: &mut [u8],
    max_depth: u32,
    change_log: Option<&ChangeLogEvent>,
) -> Result<()> {
    check_canopy_bytes(canopy_bytes)?;
    let canopy = cast_slice_mut::<u8, Node>(canopy_bytes);
    let path_len = get_cached_path_length(canopy, max_depth)?;
    if let Some(cl_event) = change_log {
        match &*cl_event {
            ChangeLogEvent::V1(cl) => {
                for path_node in cl.path.iter().rev().skip(1).take(path_len as usize) {
                    canopy[(path_node.index - 2) as usize] = path_node.node;
                }
            }
        }
    }
    Ok(())
}
pub fn fill_in_proof_from_canopy(
    canopy_bytes: &[u8],
    max_depth: u32,
    index: u32,
    proof: &mut Vec<Node>,
) -> Result<()> {
    let mut empty_node_cache = Box::new([EMPTY; MAX_SUPPORTED_DEPTH]);
    check_canopy_bytes(canopy_bytes)?;
    let canopy = cast_slice::<u8, Node>(canopy_bytes);
    let path_len = get_cached_path_length(canopy, max_depth)?;
    let mut node_idx = ((1 << max_depth) + index) >> (max_depth - path_len);
    let mut inferred_nodes = vec![];
    while node_idx > 1 {
        let shifted_index = node_idx as usize - 2;
        let cached_idx = if shifted_index % 2 == 0 {
            shifted_index + 1
        } else {
            shifted_index - 1
        };
        if canopy[cached_idx] == EMPTY {
            let level = max_depth - (31 - node_idx.leading_zeros());
            let empty_node = empty_node_cached::<MAX_SUPPORTED_DEPTH>(level, &mut empty_node_cache);
            inferred_nodes.push(empty_node);
        } else {
            inferred_nodes.push(canopy[cached_idx]);
        }
        node_idx >>= 1;
    }
    let overlap = (proof.len() + inferred_nodes.len()).saturating_sub(max_depth as usize);
    proof.extend(inferred_nodes.iter().skip(overlap));
    Ok(())
}
pub fn set_canopy_leaf_nodes(
    canopy_bytes: &mut [u8],
    max_depth: u32,
    start_index: u32,
    nodes: &[Node],
) -> Result<()> {
    check_canopy_bytes(canopy_bytes)?;
    let canopy = cast_slice_mut::<u8, Node>(canopy_bytes);
    let path_len = get_cached_path_length(canopy, max_depth)?;
    if path_len == 0 {
        return err!(AccountCompressionError::CanopyNotAllocated);
    }
    let start_canopy_node = leaf_node_index_to_canopy_index(path_len, start_index)?;
    let start_canopy_idx = start_canopy_node - 2;
    for (i, node) in nodes.iter().enumerate() {
        canopy[start_canopy_idx + i] = *node;
    }
    let mut start_canopy_node = start_canopy_node;
    let mut end_canopy_node = start_canopy_node + nodes.len() - 1;
    let mut empty_node_cache = Box::new([EMPTY; MAX_SUPPORTED_DEPTH]);
    let leaf_node_level = max_depth - path_len;
    for level in leaf_node_level + 1..max_depth {
        start_canopy_node >>= 1;
        end_canopy_node >>= 1;
        for node in start_canopy_node..end_canopy_node + 1 {
            let left_child = get_value_for_node::<MAX_SUPPORTED_DEPTH>(
                node << 1,
                level - 1,
                canopy,
                &mut empty_node_cache,
            );
            let right_child = get_value_for_node::<MAX_SUPPORTED_DEPTH>(
                (node << 1) + 1,
                level - 1,
                canopy,
                &mut empty_node_cache,
            );
            canopy[node - 2].copy_from_slice(hashv(&[&left_child, &right_child]).as_ref());
        }
    }
    Ok(())
}
pub fn check_canopy_root(canopy_bytes: &[u8], expected_root: &Node, max_depth: u32) -> Result<()> {
    check_canopy_bytes(canopy_bytes)?;
    let canopy = cast_slice::<u8, Node>(canopy_bytes);
    if canopy.is_empty() {
        return Ok(());
    }
    let mut empty_node_cache = Box::new([EMPTY; MAX_SUPPORTED_DEPTH]);
    let left_root_child =
        get_value_for_node::<MAX_SUPPORTED_DEPTH>(2, max_depth - 1, canopy, &mut empty_node_cache);
    let right_root_child =
        get_value_for_node::<MAX_SUPPORTED_DEPTH>(3, max_depth - 1, canopy, &mut empty_node_cache);
    let actual_root = hashv(&[&left_root_child, &right_root_child]).to_bytes();
    if actual_root != *expected_root {
        msg!(
            "Canopy root mismatch. Expected: {:?}, Actual: {:?}",
            expected_root,
            actual_root
        );
        err!(AccountCompressionError::CanopyRootMismatch)
    } else {
        Ok(())
    }
}
pub fn check_canopy_no_nodes_to_right_of_index(
    canopy_bytes: &[u8],
    max_depth: u32,
    index: u32,
) -> Result<()> {
    check_canopy_bytes(canopy_bytes)?;
    check_index(index, max_depth)?;
    let canopy = cast_slice::<u8, Node>(canopy_bytes);
    let path_len = get_cached_path_length(canopy, max_depth)?;
    let mut node_idx = ((1 << max_depth) + index) >> (max_depth - path_len);
    while node_idx & (node_idx + 1) != 0 {
        node_idx += 1;
        node_idx >>= node_idx.trailing_zeros();
        let shifted_index = node_idx as usize - 2;
        if canopy[shifted_index] != EMPTY {
            msg!("Canopy node at index {} is not empty", shifted_index);
            return err!(AccountCompressionError::CanopyRightmostLeafMismatch);
        }
    }
    Ok(())
}
#[inline(always)]
fn check_index(index: u32, at_depth: u32) -> Result<()> {
    if at_depth > MAX_SUPPORTED_DEPTH as u32 {
        return err!(AccountCompressionError::ConcurrentMerkleTreeConstantsError);
    }
    if at_depth == 0 {
        return err!(AccountCompressionError::ConcurrentMerkleTreeConstantsError);
    }
    if index >= (1 << at_depth) {
        return err!(AccountCompressionError::LeafIndexOutOfBounds);
    }
    Ok(())
}
#[inline(always)]
fn get_value_for_node<const N: usize>(
    node_idx: usize,
    level: u32,
    canopy: &[Node],
    empty_node_cache: &mut [Node; N],
) -> Node {
    if canopy[node_idx - 2] != EMPTY {
        return canopy[node_idx - 2];
    }
    empty_node_cached_mut::<N>(level, empty_node_cache)
}
#[inline(always)]
fn leaf_node_index_to_canopy_index(path_len: u32, index: u32) -> Result<usize> {
    check_index(index, path_len)?;
    Ok((1 << path_len) + index as usize)
}