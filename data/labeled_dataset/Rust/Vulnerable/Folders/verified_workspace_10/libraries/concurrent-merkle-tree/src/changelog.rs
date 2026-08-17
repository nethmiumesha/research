use crate::{
    hash::hash_to_parent,
    node::{Node, EMPTY},
};
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
#[repr(C)]
pub struct ChangeLog<const MAX_DEPTH: usize> {
    pub root: Node,
    pub path: [Node; MAX_DEPTH],
    pub index: u32,
    pub _padding: u32,
}
impl<const MAX_DEPTH: usize> Default for ChangeLog<MAX_DEPTH> {
    fn default() -> Self {
        Self {
            root: EMPTY,
            path: [EMPTY; MAX_DEPTH],
            index: 0,
            _padding: 0,
        }
    }
}
impl<const MAX_DEPTH: usize> ChangeLog<MAX_DEPTH> {
    pub fn new(root: Node, path: [Node; MAX_DEPTH], index: u32) -> Self {
        Self {
            root,
            path,
            index,
            _padding: 0,
        }
    }
    pub fn get_leaf(&self) -> Node {
        self.path[0]
    }
    pub fn replace_and_recompute_path(
        &mut self,
        index: u32,
        mut node: Node,
        proof: &[Node],
    ) -> Node {
        self.index = index;
        for (i, sibling) in proof.iter().enumerate() {
            self.path[i] = node;
            hash_to_parent(&mut node, sibling, self.index >> i & 1 == 0);
        }
        self.root = node;
        node
    }
    pub fn update_proof_or_leaf(
        &self,
        leaf_index: u32,
        proof: &mut [Node; MAX_DEPTH],
        leaf: &mut Node,
    ) {
        let padding: usize = 32 - MAX_DEPTH;
        if leaf_index != self.index {
            let common_path_len = ((leaf_index ^ self.index) << padding).leading_zeros() as usize;
            let critbit_index = (MAX_DEPTH - 1) - common_path_len;
            proof[critbit_index] = self.path[critbit_index];
        } else {
            *leaf = self.get_leaf();
        }
    }
}