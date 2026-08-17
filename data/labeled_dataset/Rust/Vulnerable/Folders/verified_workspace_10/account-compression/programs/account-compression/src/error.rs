use anchor_lang::{
    prelude::*,
    solana_program::{msg, program_error::ProgramError},
};
use bytemuck::PodCastError;
use spl_concurrent_merkle_tree::error::ConcurrentMerkleTreeError;
use std::any::type_name;
use std::mem::size_of;
#[error_code]
pub enum AccountCompressionError {
    #[msg("Incorrect leaf length. Expected vec of 32 bytes")]
    IncorrectLeafLength,
    #[msg("Concurrent merkle tree error")]
    ConcurrentMerkleTreeError,
    #[msg("Issue zero copying concurrent merkle tree data")]
    ZeroCopyError,
    #[msg("An unsupported max depth or max buffer size constant was provided")]
    ConcurrentMerkleTreeConstantsError,
    #[msg("Expected a different byte length for the merkle tree canopy")]
    CanopyLengthMismatch,
    #[msg("Provided authority does not match expected tree authority")]
    IncorrectAuthority,
    #[msg("Account is owned by a different program, expected it to be owned by this program")]
    IncorrectAccountOwner,
    #[msg("Account provided has incorrect account type")]
    IncorrectAccountType,
    #[msg("Leaf index of concurrent merkle tree is out of bounds")]
    LeafIndexOutOfBounds,
    #[msg("Tree was initialized without allocating space for the canopy")]
    CanopyNotAllocated,
    #[msg("Tree was already initialized")]
    TreeAlreadyInitialized,
    #[msg("Tree header was not initialized for batch processing")]
    BatchNotInitialized,
    #[msg("Canopy root does not match the root of the tree")]
    CanopyRootMismatch,
    #[msg("Canopy contains nodes to the right of the rightmost leaf of the tree")]
    CanopyRightmostLeafMismatch,
}
impl From<&ConcurrentMerkleTreeError> for AccountCompressionError {
    fn from(_error: &ConcurrentMerkleTreeError) -> Self {
        AccountCompressionError::ConcurrentMerkleTreeError
    }
}
pub fn error_msg<T>(data_len: usize) -> impl Fn(PodCastError) -> ProgramError {
    move |_: PodCastError| -> ProgramError {
        msg!(
            "Failed to load {}. Size is {}, expected {}",
            type_name::<T>(),
            data_len,
            size_of::<T>(),
        );
        ProgramError::InvalidAccountData
    }
}