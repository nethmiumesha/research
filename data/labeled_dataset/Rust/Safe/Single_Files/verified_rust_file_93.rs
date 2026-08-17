use crate::node::Node;
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
#[repr(C)]
pub struct Path<const MAX_DEPTH: usize> {
    pub proof: [Node; MAX_DEPTH],
    pub leaf: Node,
    pub index: u32,
    pub _padding: u32,
}
impl<const MAX_DEPTH: usize> Default for Path<MAX_DEPTH> {
    fn default() -> Self {
        Self {
            proof: [Node::default(); MAX_DEPTH],
            leaf: Node::default(),
            index: 0,
            _padding: 0,
        }
    }
}