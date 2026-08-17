use thiserror::Error;
#[derive(Error, Debug, PartialEq, Eq)]
pub enum ConcurrentMerkleTreeError {
    #[error("Received an index larger than the rightmost index, or greater than (1 << max_depth)")]
    LeafIndexOutOfBounds,
    #[error("Invalid root recomputed from proof")]
    InvalidProof,
    #[error("Cannot append an empty node")]
    CannotAppendEmptyNode,
    #[error("Tree is full, cannot append")]
    TreeFull,
    #[error("Tree already initialized")]
    TreeAlreadyInitialized,
    #[error("Tree needs to be initialized before using")]
    TreeNotInitialized,
    #[error("Root not found in changelog buffer")]
    RootNotFound,
    #[error("This tree's current leaf value does not match the supplied proof's leaf value")]
    LeafContentsModified,
    #[error("Tree is not empty")]
    TreeNonEmpty,
}