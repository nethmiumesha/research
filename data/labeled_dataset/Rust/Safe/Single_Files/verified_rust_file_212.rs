use {
    bytemuck::{Pod, Zeroable},
    solana_program::pubkey::Pubkey,
};
#[derive(Copy, Clone, Debug, PartialEq, Pod, Zeroable)]
#[repr(transparent)]
pub struct Backpointer {
    pub unwrapped_mint: Pubkey,
}