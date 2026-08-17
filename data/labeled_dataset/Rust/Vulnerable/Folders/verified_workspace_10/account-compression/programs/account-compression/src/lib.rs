use anchor_lang::{
    prelude::*,
    solana_program::sysvar::{clock::Clock, rent::Rent},
};
use borsh::{BorshDeserialize, BorshSerialize};
pub mod canopy;
pub mod concurrent_tree_wrapper;
pub mod error;
pub mod events;
#[macro_use]
pub mod macros;
mod noop;
pub mod state;
pub mod zero_copy;
pub use crate::noop::{wrap_application_data_v1, Noop};
use crate::canopy::{
    check_canopy_bytes, check_canopy_no_nodes_to_right_of_index, check_canopy_root,
    fill_in_proof_from_canopy, set_canopy_leaf_nodes, update_canopy,
};
use crate::concurrent_tree_wrapper::*;
pub use crate::error::AccountCompressionError;
pub use crate::events::{AccountCompressionEvent, ChangeLogEvent};
use crate::noop::wrap_event;
use crate::state::{
    merkle_tree_get_size, ConcurrentMerkleTreeHeader, CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1,
};
pub use spl_concurrent_merkle_tree::{
    concurrent_merkle_tree::{ConcurrentMerkleTree, FillEmptyOrAppendArgs},
    error::ConcurrentMerkleTreeError,
    node::Node,
    node::EMPTY,
};
declare_id!("cmtDvXumGCrqC1Age74AVPhSRVXJMd8PJS91L8KbNCK");
#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(zero)]
    pub merkle_tree: UncheckedAccount<'info>,
    pub authority: Signer<'info>,
    pub noop: Program<'info, Noop>,
}
#[derive(Accounts)]
pub struct Modify<'info> {
    #[account(mut)]
    pub merkle_tree: UncheckedAccount<'info>,
    pub authority: Signer<'info>,
    pub noop: Program<'info, Noop>,
}
#[derive(Accounts)]
pub struct VerifyLeaf<'info> {
    pub merkle_tree: UncheckedAccount<'info>,
}
#[derive(Accounts)]
pub struct TransferAuthority<'info> {
    #[account(mut)]
    pub merkle_tree: UncheckedAccount<'info>,
    pub authority: Signer<'info>,
}
#[derive(Accounts)]
pub struct CloseTree<'info> {
    #[account(mut)]
    pub merkle_tree: AccountInfo<'info>,
    pub authority: Signer<'info>,
    #[account(mut)]
    pub recipient: AccountInfo<'info>,
}
#[program]
pub mod spl_account_compression {
    use super::*;
    pub fn init_empty_merkle_tree(
        ctx: Context<Initialize>,
        max_depth: u32,
        max_buffer_size: u32,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (mut header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let mut header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.initialize(
            max_depth,
            max_buffer_size,
            &ctx.accounts.authority.key(),
            Clock::get()?.slot,
        );
        header.serialize(&mut header_bytes)?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        let id = ctx.accounts.merkle_tree.key();
        let change_log_event = merkle_tree_initialize_empty(&header, id, tree_bytes)?;
        wrap_event(
            &AccountCompressionEvent::ChangeLog(*change_log_event),
            &ctx.accounts.noop,
        )?;
        update_canopy(canopy_bytes, header.get_max_depth(), None)
    }
    pub fn prepare_batch_merkle_tree(
        ctx: Context<Initialize>,
        max_depth: u32,
        max_buffer_size: u32,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (mut header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let mut header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.initialize_batched(
            max_depth,
            max_buffer_size,
            &ctx.accounts.authority.key(),
            Clock::get()?.slot,
        );
        header.serialize(&mut header_bytes)?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (_tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        check_canopy_bytes(canopy_bytes)
    }
    pub fn append_canopy_nodes(
        ctx: Context<Modify>,
        start_index: u32,
        canopy_nodes: Vec<[u8; 32]>,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        header.assert_is_batch_initialized()?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        require!(
            tree_bytes_uninitialized(tree_bytes),
            AccountCompressionError::TreeAlreadyInitialized
        );
        set_canopy_leaf_nodes(
            canopy_bytes,
            header.get_max_depth(),
            start_index,
            &canopy_nodes,
        )
    }
    pub fn init_prepared_tree_with_root(
        ctx: Context<Modify>,
        root: [u8; 32],
        rightmost_leaf: [u8; 32],
        rightmost_index: u32,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        header.assert_is_batch_initialized()?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        check_canopy_root(canopy_bytes, &root, header.get_max_depth())?;
        check_canopy_no_nodes_to_right_of_index(
            canopy_bytes,
            header.get_max_depth(),
            rightmost_index,
        )?;
        let mut proof = vec![];
        for node in ctx.remaining_accounts.iter() {
            proof.push(node.key().to_bytes());
        }
        fill_in_proof_from_canopy(
            canopy_bytes,
            header.get_max_depth(),
            rightmost_index,
            &mut proof,
        )?;
        assert_eq!(proof.len(), header.get_max_depth() as usize);
        let id = ctx.accounts.merkle_tree.key();
        let args = &InitializeWithRootArgs {
            root,
            rightmost_leaf,
            proof_vec: proof,
            index: rightmost_index,
        };
        let change_log = merkle_tree_initialize_with_root(&header, id, tree_bytes, args)?;
        update_canopy(canopy_bytes, header.get_max_depth(), Some(&change_log))?;
        wrap_event(
            &AccountCompressionEvent::ChangeLog(*change_log),
            &ctx.accounts.noop,
        )
    }
    pub fn replace_leaf(
        ctx: Context<Modify>,
        root: [u8; 32],
        previous_leaf: [u8; 32],
        new_leaf: [u8; 32],
        index: u32,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        header.assert_valid_leaf_index(index)?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        let mut proof = vec![];
        for node in ctx.remaining_accounts.iter() {
            proof.push(node.key().to_bytes());
        }
        fill_in_proof_from_canopy(canopy_bytes, header.get_max_depth(), index, &mut proof)?;
        let id = ctx.accounts.merkle_tree.key();
        let args = &SetLeafArgs {
            current_root: root,
            previous_leaf,
            new_leaf,
            proof_vec: proof,
            index,
        };
        let change_log_event = merkle_tree_set_leaf(&header, id, tree_bytes, args)?;
        update_canopy(
            canopy_bytes,
            header.get_max_depth(),
            Some(&change_log_event),
        )?;
        wrap_event(
            &AccountCompressionEvent::ChangeLog(*change_log_event),
            &ctx.accounts.noop,
        )
    }
    pub fn transfer_authority(
        ctx: Context<TransferAuthority>,
        new_authority: Pubkey,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (mut header_bytes, _) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let mut header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        header.set_new_authority(&new_authority);
        header.serialize(&mut header_bytes)?;
        Ok(())
    }
    pub fn verify_leaf(
        ctx: Context<VerifyLeaf>,
        root: [u8; 32],
        leaf: [u8; 32],
        index: u32,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid()?;
        header.assert_valid_leaf_index(index)?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at(merkle_tree_size);
        let mut proof = vec![];
        for node in ctx.remaining_accounts.iter() {
            proof.push(node.key().to_bytes());
        }
        fill_in_proof_from_canopy(canopy_bytes, header.get_max_depth(), index, &mut proof)?;
        let id = ctx.accounts.merkle_tree.key();
        let args = &ProveLeafArgs {
            current_root: root,
            leaf,
            proof_vec: proof,
            index,
        };
        merkle_tree_prove_leaf(&header, id, tree_bytes, args)?;
        Ok(())
    }
    pub fn append(ctx: Context<Modify>, leaf: [u8; 32]) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        let id = ctx.accounts.merkle_tree.key();
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        let change_log_event = merkle_tree_append_leaf(&header, id, tree_bytes, &leaf)?;
        update_canopy(
            canopy_bytes,
            header.get_max_depth(),
            Some(&change_log_event),
        )?;
        wrap_event(
            &AccountCompressionEvent::ChangeLog(*change_log_event),
            &ctx.accounts.noop,
        )
    }
    pub fn insert_or_append(
        ctx: Context<Modify>,
        root: [u8; 32],
        leaf: [u8; 32],
        index: u32,
    ) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        header.assert_valid_leaf_index(index)?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        let mut proof = vec![];
        for node in ctx.remaining_accounts.iter() {
            proof.push(node.key().to_bytes());
        }
        fill_in_proof_from_canopy(canopy_bytes, header.get_max_depth(), index, &mut proof)?;
        let id = ctx.accounts.merkle_tree.key();
        let args = &FillEmptyOrAppendArgs {
            current_root: root,
            leaf,
            proof_vec: proof,
            index,
        };
        let change_log_event = merkle_tree_fill_empty_or_append(&header, id, tree_bytes, args)?;
        update_canopy(
            canopy_bytes,
            header.get_max_depth(),
            Some(&change_log_event),
        )?;
        wrap_event(
            &AccountCompressionEvent::ChangeLog(*change_log_event),
            &ctx.accounts.noop,
        )
    }
    pub fn close_empty_tree(ctx: Context<CloseTree>) -> Result<()> {
        require_eq!(
            *ctx.accounts.merkle_tree.owner,
            crate::id(),
            AccountCompressionError::IncorrectAccountOwner
        );
        let mut merkle_tree_bytes = ctx.accounts.merkle_tree.try_borrow_mut_data()?;
        let (header_bytes, rest) =
            merkle_tree_bytes.split_at_mut(CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1);
        let header = ConcurrentMerkleTreeHeader::try_from_slice(header_bytes)?;
        header.assert_valid_authority(&ctx.accounts.authority.key())?;
        let merkle_tree_size = merkle_tree_get_size(&header)?;
        let (tree_bytes, canopy_bytes) = rest.split_at_mut(merkle_tree_size);
        let id = ctx.accounts.merkle_tree.key();
        assert_tree_is_empty(&header, id, tree_bytes)?;
        let dest_starting_lamports = ctx.accounts.recipient.lamports();
        **ctx.accounts.recipient.lamports.borrow_mut() = dest_starting_lamports
            .checked_add(ctx.accounts.merkle_tree.lamports())
            .unwrap();
        **ctx.accounts.merkle_tree.lamports.borrow_mut() = 0;
        header_bytes.fill(0);
        tree_bytes.fill(0);
        canopy_bytes.fill(0);
        Ok(())
    }
}