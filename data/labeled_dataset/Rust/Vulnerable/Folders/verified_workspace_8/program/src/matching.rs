use std::cell::RefMut;
use std::convert::TryFrom;
use std::mem::size_of;
use bytemuck::{cast, cast_mut, cast_ref};
use fixed::types::I80F48;
use num_enum::{IntoPrimitive, TryFromPrimitive};
use serde::{Deserialize, Serialize};
use solana_program::account_info::AccountInfo;
use solana_program::clock::Clock;
use solana_program::msg;
use solana_program::pubkey::Pubkey;
use solana_program::sysvar::rent::Rent;
use solana_program::sysvar::Sysvar;
use static_assertions::const_assert_eq;
use mango_common::Loadable;
use mango_logs::{mango_emit_stack, ReferralFeeAccrualLog};
use mango_macro::{Loadable, Pod};
use crate::error::{check_assert, MangoError, MangoErrorCode, MangoResult, SourceFileId};
use crate::ids::mngo_token;
use crate::queue::{EventQueue, FillEvent, OutEvent};
use crate::state::{
    DataType, MangoAccount, MangoCache, MangoGroup, MetaData, PerpMarket, PerpMarketCache,
    PerpMarketInfo, TokenInfo, CENTIBPS_PER_UNIT, MAX_PERP_OPEN_ORDERS, ZERO_I80F48,
};
use crate::utils::emit_perp_balances;
declare_check_assert_macros!(SourceFileId::Matching);
pub type NodeHandle = u32;
const NODE_SIZE: usize = 88;
const DROP_EXPIRED_ORDER_LIMIT: usize = 5;
#[derive(IntoPrimitive, TryFromPrimitive)]
#[repr(u32)]
pub enum NodeTag {
    Uninitialized = 0,
    InnerNode = 1,
    LeafNode = 2,
    FreeNode = 3,
    LastFreeNode = 4,
}
#[derive(Copy, Clone, Pod)]
#[repr(C)]
pub struct InnerNode {
    pub tag: u32,
    pub prefix_len: u32,
    pub key: i128,
    pub children: [NodeHandle; 2],
    pub child_earliest_expiry: [u64; 2],
    pub padding: [u8; NODE_SIZE - 48],
}
impl InnerNode {
    fn new(prefix_len: u32, key: i128) -> Self {
        Self {
            tag: NodeTag::InnerNode.into(),
            prefix_len,
            key,
            children: [0; 2],
            child_earliest_expiry: [u64::MAX; 2],
            padding: [0; NODE_SIZE - 48],
        }
    }
    fn walk_down(&self, search_key: i128) -> (NodeHandle, bool) {
        let crit_bit_mask = 1i128 << (127 - self.prefix_len);
        let crit_bit = (search_key & crit_bit_mask) != 0;
        (self.children[crit_bit as usize], crit_bit)
    }
    #[inline(always)]
    pub fn earliest_expiry(&self) -> u64 {
        std::cmp::min(self.child_earliest_expiry[0], self.child_earliest_expiry[1])
    }
}
#[derive(Debug, Copy, Clone, PartialEq, Eq, Pod)]
#[repr(C)]
pub struct LeafNode {
    pub tag: u32,
    pub owner_slot: u8,
    pub order_type: OrderType,
    pub version: u8,
    pub time_in_force: u8,
    pub key: i128,
    pub owner: Pubkey,
    pub quantity: i64,
    pub client_order_id: u64,
    pub best_initial: i64,
    pub timestamp: u64,
}
#[inline(always)]
fn key_to_price(key: i128) -> i64 {
    (key >> 64) as i64
}
impl LeafNode {
    pub fn new(
        version: u8,
        owner_slot: u8,
        key: i128,
        owner: Pubkey,
        quantity: i64,
        client_order_id: u64,
        timestamp: u64,
        best_initial: i64,
        order_type: OrderType,
        time_in_force: u8,
    ) -> Self {
        Self {
            tag: NodeTag::LeafNode.into(),
            owner_slot,
            order_type,
            version,
            time_in_force,
            key,
            owner,
            quantity,
            client_order_id,
            best_initial,
            timestamp,
        }
    }
    #[inline(always)]
    pub fn price(&self) -> i64 {
        key_to_price(self.key)
    }
    #[inline(always)]
    pub fn expiry(&self) -> u64 {
        if self.time_in_force == 0 {
            u64::MAX
        } else {
            self.timestamp + self.time_in_force as u64
        }
    }
    #[inline(always)]
    pub fn is_valid(&self, now_ts: u64) -> bool {
        self.time_in_force == 0 || now_ts < self.timestamp + self.time_in_force as u64
    }
}
#[derive(Copy, Clone, Pod)]
#[repr(C)]
struct FreeNode {
    tag: u32,
    next: NodeHandle,
    padding: [u8; NODE_SIZE - 8],
}
#[derive(Copy, Clone, Pod)]
#[repr(C)]
pub struct AnyNode {
    pub tag: u32,
    pub data: [u8; NODE_SIZE - 4],
}
const_assert_eq!(size_of::<AnyNode>(), size_of::<InnerNode>());
const_assert_eq!(size_of::<AnyNode>(), size_of::<LeafNode>());
const_assert_eq!(size_of::<AnyNode>(), size_of::<FreeNode>());
enum NodeRef<'a> {
    Inner(&'a InnerNode),
    Leaf(&'a LeafNode),
}
enum NodeRefMut<'a> {
    Inner(&'a mut InnerNode),
    Leaf(&'a mut LeafNode),
}
impl AnyNode {
    fn key(&self) -> Option<i128> {
        match self.case()? {
            NodeRef::Inner(inner) => Some(inner.key),
            NodeRef::Leaf(leaf) => Some(leaf.key),
        }
    }
    fn children(&self) -> Option<[NodeHandle; 2]> {
        match self.case().unwrap() {
            NodeRef::Inner(&InnerNode { children, .. }) => Some(children),
            NodeRef::Leaf(_) => None,
        }
    }
    fn case(&self) -> Option<NodeRef> {
        match NodeTag::try_from(self.tag) {
            Ok(NodeTag::InnerNode) => Some(NodeRef::Inner(cast_ref(self))),
            Ok(NodeTag::LeafNode) => Some(NodeRef::Leaf(cast_ref(self))),
            _ => None,
        }
    }
    fn case_mut(&mut self) -> Option<NodeRefMut> {
        match NodeTag::try_from(self.tag) {
            Ok(NodeTag::InnerNode) => Some(NodeRefMut::Inner(cast_mut(self))),
            Ok(NodeTag::LeafNode) => Some(NodeRefMut::Leaf(cast_mut(self))),
            _ => None,
        }
    }
    #[inline]
    pub fn as_leaf(&self) -> Option<&LeafNode> {
        match self.case() {
            Some(NodeRef::Leaf(leaf_ref)) => Some(leaf_ref),
            _ => None,
        }
    }
    #[inline]
    pub fn as_leaf_mut(&mut self) -> Option<&mut LeafNode> {
        match self.case_mut() {
            Some(NodeRefMut::Leaf(leaf_ref)) => Some(leaf_ref),
            _ => None,
        }
    }
    #[inline]
    pub fn as_inner(&self) -> Option<&InnerNode> {
        match self.case() {
            Some(NodeRef::Inner(inner_ref)) => Some(inner_ref),
            _ => None,
        }
    }
    #[inline]
    pub fn as_inner_mut(&mut self) -> Option<&mut InnerNode> {
        match self.case_mut() {
            Some(NodeRefMut::Inner(inner_ref)) => Some(inner_ref),
            _ => None,
        }
    }
    #[inline]
    pub fn earliest_expiry(&self) -> u64 {
        match self.case().unwrap() {
            NodeRef::Inner(inner) => inner.earliest_expiry(),
            NodeRef::Leaf(leaf) => leaf.expiry(),
        }
    }
}
impl AsRef<AnyNode> for InnerNode {
    fn as_ref(&self) -> &AnyNode {
        cast_ref(self)
    }
}
impl AsRef<AnyNode> for LeafNode {
    #[inline]
    fn as_ref(&self) -> &AnyNode {
        cast_ref(self)
    }
}
#[derive(
    Eq, PartialEq, Copy, Clone, TryFromPrimitive, IntoPrimitive, Debug, Serialize, Deserialize,
)]
#[repr(u8)]
#[serde(into = "u8", try_from = "u8")]
pub enum OrderType {
    Limit = 0,
    ImmediateOrCancel = 1,
    PostOnly = 2,
    Market = 3,
    PostOnlySlide = 4,
}
#[derive(
    Eq, PartialEq, Copy, Clone, TryFromPrimitive, IntoPrimitive, Debug, Serialize, Deserialize,
)]
#[repr(u8)]
#[serde(into = "u8", try_from = "u8")]
pub enum Side {
    Bid = 0,
    Ask = 1,
}
#[derive(
    Eq, PartialEq, Copy, Clone, TryFromPrimitive, IntoPrimitive, Debug, Serialize, Deserialize,
)]
#[repr(u8)]
#[serde(into = "u8", try_from = "u8")]
pub enum ExpiryType {
    Absolute,
    Relative,
}
pub const MAX_BOOK_NODES: usize = 1024;
#[derive(Copy, Clone, Pod, Loadable)]
#[repr(C)]
pub struct BookSide {
    pub meta_data: MetaData,
    bump_index: usize,
    free_list_len: usize,
    free_list_head: NodeHandle,
    root_node: NodeHandle,
    leaf_count: usize,
    nodes: [AnyNode; MAX_BOOK_NODES],
}
pub struct BookSideIter<'a> {
    book_side: &'a BookSide,
    stack: Vec<&'a InnerNode>,
    next_leaf: Option<(NodeHandle, &'a LeafNode)>,
    left: usize,
    right: usize,
    now_ts: u64,
}
impl<'a> BookSideIter<'a> {
    pub fn new(book_side: &'a BookSide, now_ts: u64) -> Self {
        let (left, right) =
            if book_side.meta_data.data_type == DataType::Bids as u8 { (1, 0) } else { (0, 1) };
        let stack = vec![];
        let mut iter = Self { book_side, stack, next_leaf: None, left, right, now_ts };
        if book_side.leaf_count != 0 {
            iter.next_leaf = iter.find_leftmost_valid_leaf(book_side.root_node);
        }
        iter
    }
    fn find_leftmost_valid_leaf(
        &mut self,
        start: NodeHandle,
    ) -> Option<(NodeHandle, &'a LeafNode)> {
        let mut current = start;
        loop {
            match self.book_side.get(current).unwrap().case().unwrap() {
                NodeRef::Inner(inner) => {
                    self.stack.push(inner);
                    current = inner.children[self.left];
                }
                NodeRef::Leaf(leaf) => {
                    if leaf.is_valid(self.now_ts) {
                        return Some((current, leaf));
                    } else {
                        match self.stack.pop() {
                            None => {
                                return None;
                            }
                            Some(inner) => {
                                current = inner.children[self.right];
                            }
                        }
                    }
                }
            }
        }
    }
}
impl<'a> Iterator for BookSideIter<'a> {
    type Item = (NodeHandle, &'a LeafNode);
    fn next(&mut self) -> Option<Self::Item> {
        if self.next_leaf.is_none() {
            return None;
        }
        let current_leaf = self.next_leaf;
        self.next_leaf = match self.stack.pop() {
            None => None,
            Some(inner) => {
                let start = inner.children[self.right];
                self.find_leftmost_valid_leaf(start)
            }
        };
        current_leaf
    }
}
impl BookSide {
    #[deprecated(
        since = "3.4.0",
        note = "use iter_valid() or iter_all_including_invalid() instead"
    )]
    pub fn iter(&self) -> BookSideIter {
        self.iter_valid(Clock::get().unwrap().unix_timestamp as u64)
    }
    pub fn iter_valid(&self, now_ts: u64) -> BookSideIter {
        BookSideIter::new(self, now_ts)
    }
    pub fn iter_all_including_invalid(&self) -> BookSideIter {
        BookSideIter::new(self, 0)
    }
    pub fn load_mut_checked<'a>(
        account: &'a AccountInfo,
        program_id: &Pubkey,
        perp_market: &PerpMarket,
    ) -> MangoResult<RefMut<'a, Self>> {
        check!(account.owner == program_id, MangoErrorCode::InvalidOwner)?;
        let state = Self::load_mut(account)?;
        check!(state.meta_data.is_initialized, MangoErrorCode::Default)?;
        match DataType::try_from(state.meta_data.data_type).unwrap() {
            DataType::Bids => check!(account.key == &perp_market.bids, MangoErrorCode::Default)?,
            DataType::Asks => check!(account.key == &perp_market.asks, MangoErrorCode::Default)?,
            _ => return Err(throw!()),
        }
        Ok(state)
    }
    pub fn load_and_init<'a>(
        account: &'a AccountInfo,
        program_id: &Pubkey,
        data_type: DataType,
        rent: &Rent,
    ) -> MangoResult<RefMut<'a, Self>> {
        check!(
            rent.is_exempt(account.lamports(), account.data_len()),
            MangoErrorCode::AccountNotRentExempt
        )?;
        let mut state = Self::load_mut(account)?;
        check!(account.owner == program_id, MangoErrorCode::InvalidOwner)?;
        check!(!state.meta_data.is_initialized, MangoErrorCode::Default)?;
        state.meta_data = MetaData::new(data_type, 0, true);
        Ok(state)
    }
    fn get_mut(&mut self, key: NodeHandle) -> Option<&mut AnyNode> {
        let node = &mut self.nodes[key as usize];
        let tag = NodeTag::try_from(node.tag);
        match tag {
            Ok(NodeTag::InnerNode) | Ok(NodeTag::LeafNode) => Some(node),
            _ => None,
        }
    }
    fn get(&self, key: NodeHandle) -> Option<&AnyNode> {
        let node = &self.nodes[key as usize];
        let tag = NodeTag::try_from(node.tag);
        match tag {
            Ok(NodeTag::InnerNode) | Ok(NodeTag::LeafNode) => Some(node),
            _ => None,
        }
    }
    pub fn remove_min(&mut self) -> Option<LeafNode> {
        self.remove_by_key(self.get(self.find_min()?)?.key()?)
    }
    pub fn remove_max(&mut self) -> Option<LeafNode> {
        self.remove_by_key(self.get(self.find_max()?)?.key()?)
    }
    pub fn remove_one_expired(&mut self, now_ts: u64) -> Option<LeafNode> {
        let (expired_h, expires_at) = self.find_earliest_expiry()?;
        if expires_at < now_ts {
            self.remove_by_key(self.get(expired_h)?.key()?)
        } else {
            None
        }
    }
    pub fn find_max(&self) -> Option<NodeHandle> {
        self.find_min_max(true)
    }
    fn root(&self) -> Option<NodeHandle> {
        if self.leaf_count == 0 {
            None
        } else {
            Some(self.root_node)
        }
    }
    pub fn find_min(&self) -> Option<NodeHandle> {
        self.find_min_max(false)
    }
    fn find_min_max(&self, find_max: bool) -> Option<NodeHandle> {
        let mut root: NodeHandle = self.root()?;
        let i = if find_max { 1 } else { 0 };
        loop {
            let root_contents = self.get(root).unwrap();
            match root_contents.case().unwrap() {
                NodeRef::Inner(&InnerNode { children, .. }) => {
                    root = children[i];
                }
                _ => return Some(root),
            }
        }
    }
    pub fn get_min(&self) -> Option<&LeafNode> {
        self.get_min_max(false)
    }
    pub fn get_max(&self) -> Option<&LeafNode> {
        self.get_min_max(true)
    }
    fn get_min_max(&self, find_max: bool) -> Option<&LeafNode> {
        let mut root: NodeHandle = self.root()?;
        let i = if find_max { 1 } else { 0 };
        loop {
            let root_contents = self.get(root)?;
            match root_contents.case()? {
                NodeRef::Inner(inner) => {
                    root = inner.children[i];
                }
                NodeRef::Leaf(leaf) => {
                    return Some(leaf);
                }
            }
        }
    }
    fn remove_by_key(&mut self, search_key: i128) -> Option<LeafNode> {
        let mut stack: Vec<(NodeHandle, bool)> = vec![];
        let mut parent_h = self.root()?;
        let (mut child_h, mut crit_bit) = match self.get(parent_h).unwrap().case().unwrap() {
            NodeRef::Leaf(&leaf) if leaf.key == search_key => {
                assert_eq!(self.leaf_count, 1);
                self.root_node = 0;
                self.leaf_count = 0;
                let _old_root = self.remove(parent_h).unwrap();
                return Some(leaf);
            }
            NodeRef::Leaf(_) => return None,
            NodeRef::Inner(inner) => inner.walk_down(search_key),
        };
        stack.push((parent_h, crit_bit));
        loop {
            match self.get(child_h).unwrap().case().unwrap() {
                NodeRef::Inner(inner) => {
                    parent_h = child_h;
                    let (new_child_h, new_crit_bit) = inner.walk_down(search_key);
                    child_h = new_child_h;
                    crit_bit = new_crit_bit;
                    stack.push((parent_h, crit_bit));
                }
                NodeRef::Leaf(leaf) => {
                    if leaf.key != search_key {
                        return None;
                    }
                    break;
                }
            }
        }
        let other_child_h = self.get(parent_h).unwrap().children().unwrap()[!crit_bit as usize];
        let other_child_node_contents = self.remove(other_child_h).unwrap();
        let new_expiry = other_child_node_contents.earliest_expiry();
        *self.get_mut(parent_h).unwrap() = other_child_node_contents;
        self.leaf_count -= 1;
        let removed_leaf: LeafNode = cast(self.remove(child_h).unwrap());
        let outdated_expiry = removed_leaf.expiry();
        stack.pop();
        self.update_parent_earliest_expiry(&stack, outdated_expiry, new_expiry);
        Some(removed_leaf)
    }
    fn remove(&mut self, key: NodeHandle) -> Option<AnyNode> {
        let val = *self.get(key)?;
        self.nodes[key as usize] = cast(FreeNode {
            tag: if self.free_list_len == 0 {
                NodeTag::LastFreeNode.into()
            } else {
                NodeTag::FreeNode.into()
            },
            next: self.free_list_head,
            padding: [0; 80],
        });
        self.free_list_len += 1;
        self.free_list_head = key;
        Some(val)
    }
    fn insert(&mut self, val: &AnyNode) -> MangoResult<NodeHandle> {
        match NodeTag::try_from(val.tag) {
            Ok(NodeTag::InnerNode) | Ok(NodeTag::LeafNode) => (),
            _ => unreachable!(),
        };
        if self.free_list_len == 0 {
            check!(
                self.bump_index < self.nodes.len() && self.bump_index < (u32::MAX as usize),
                MangoErrorCode::OutOfSpace
            )?;
            self.nodes[self.bump_index] = *val;
            let key = self.bump_index as u32;
            self.bump_index += 1;
            return Ok(key);
        }
        let key = self.free_list_head;
        let node = &mut self.nodes[key as usize];
        match NodeTag::try_from(node.tag) {
            Ok(NodeTag::FreeNode) => assert!(self.free_list_len > 1),
            Ok(NodeTag::LastFreeNode) => assert_eq!(self.free_list_len, 1),
            _ => unreachable!(),
        };
        self.free_list_head = cast_ref::<AnyNode, FreeNode>(node).next;
        self.free_list_len -= 1;
        *node = *val;
        Ok(key)
    }
    pub fn insert_leaf(
        &mut self,
        new_leaf: &LeafNode,
    ) -> MangoResult<(NodeHandle, Option<LeafNode>)> {
        let mut stack: Vec<(NodeHandle, bool)> = vec![];
        let mut root: NodeHandle = match self.root() {
            Some(h) => h,
            None => {
                let handle = self.insert(new_leaf.as_ref())?;
                self.root_node = handle;
                self.leaf_count = 1;
                return Ok((handle, None));
            }
        };
        loop {
            let root_contents = *self.get(root).unwrap();
            let root_key = root_contents.key().unwrap();
            if root_key == new_leaf.key {
                if let Some(NodeRef::Leaf(&old_root_as_leaf)) = root_contents.case() {
                    *self.get_mut(root).unwrap() = *new_leaf.as_ref();
                    self.update_parent_earliest_expiry(
                        &stack,
                        old_root_as_leaf.expiry(),
                        new_leaf.expiry(),
                    );
                    return Ok((root, Some(old_root_as_leaf)));
                }
            }
            let shared_prefix_len: u32 = (root_key ^ new_leaf.key).leading_zeros();
            match root_contents.case() {
                None => unreachable!(),
                Some(NodeRef::Inner(inner)) => {
                    let keep_old_root = shared_prefix_len >= inner.prefix_len;
                    if keep_old_root {
                        let (child, crit_bit) = inner.walk_down(new_leaf.key);
                        stack.push((root, crit_bit));
                        root = child;
                        continue;
                    };
                }
                _ => (),
            };
            let crit_bit_mask: i128 = 1i128 << (127 - shared_prefix_len);
            let new_leaf_crit_bit = (crit_bit_mask & new_leaf.key) != 0;
            let old_root_crit_bit = !new_leaf_crit_bit;
            let new_leaf_handle = self.insert(new_leaf.as_ref())?;
            let moved_root_handle = match self.insert(&root_contents) {
                Ok(h) => h,
                Err(e) => {
                    self.remove(new_leaf_handle).unwrap();
                    return Err(e);
                }
            };
            let new_root: &mut InnerNode = cast_mut(self.get_mut(root).unwrap());
            *new_root = InnerNode::new(shared_prefix_len, new_leaf.key);
            new_root.children[new_leaf_crit_bit as usize] = new_leaf_handle;
            new_root.children[old_root_crit_bit as usize] = moved_root_handle;
            let new_leaf_expiry = new_leaf.expiry();
            let old_root_expiry = root_contents.earliest_expiry();
            new_root.child_earliest_expiry[new_leaf_crit_bit as usize] = new_leaf_expiry;
            new_root.child_earliest_expiry[old_root_crit_bit as usize] = old_root_expiry;
            if new_leaf_expiry < old_root_expiry {
                self.update_parent_earliest_expiry(&stack, old_root_expiry, new_leaf_expiry);
            }
            self.leaf_count += 1;
            return Ok((new_leaf_handle, None));
        }
    }
    pub fn is_full(&self) -> bool {
        self.free_list_len <= 1 && self.bump_index >= self.nodes.len() - 1
    }
    pub fn is_empty(&self) -> bool {
        self.leaf_count == 0
    }
    fn update_parent_earliest_expiry(
        &mut self,
        stack: &[(NodeHandle, bool)],
        mut outdated_expiry: u64,
        mut new_expiry: u64,
    ) {
        for (parent_h, crit_bit) in stack.iter().rev() {
            let parent = self.get_mut(*parent_h).unwrap().as_inner_mut().unwrap();
            if parent.child_earliest_expiry[*crit_bit as usize] != outdated_expiry {
                break;
            }
            outdated_expiry = parent.earliest_expiry();
            parent.child_earliest_expiry[*crit_bit as usize] = new_expiry;
            new_expiry = parent.earliest_expiry();
        }
    }
    pub fn find_earliest_expiry(&self) -> Option<(NodeHandle, u64)> {
        let mut current: NodeHandle = match self.root() {
            Some(h) => h,
            None => return None,
        };
        loop {
            let contents = *self.get(current).unwrap();
            match contents.case() {
                None => unreachable!(),
                Some(NodeRef::Inner(inner)) => {
                    current = inner.children[(inner.child_earliest_expiry[0]
                        > inner.child_earliest_expiry[1])
                        as usize];
                }
                _ => {
                    return Some((current, contents.earliest_expiry()));
                }
            };
        }
    }
}
pub struct Book<'a> {
    pub bids: RefMut<'a, BookSide>,
    pub asks: RefMut<'a, BookSide>,
}
impl<'a> Book<'a> {
    pub fn load_checked(
        program_id: &Pubkey,
        bids_ai: &'a AccountInfo,
        asks_ai: &'a AccountInfo,
        perp_market: &PerpMarket,
    ) -> MangoResult<Self> {
        check!(bids_ai.key == &perp_market.bids, MangoErrorCode::InvalidAccount)?;
        check!(asks_ai.key == &perp_market.asks, MangoErrorCode::InvalidAccount)?;
        Ok(Self {
            bids: BookSide::load_mut_checked(bids_ai, program_id, perp_market)?,
            asks: BookSide::load_mut_checked(asks_ai, program_id, perp_market)?,
        })
    }
    pub fn get_best_bid_price(&self, now_ts: u64) -> Option<i64> {
        Some(self.bids.iter_valid(now_ts).next()?.1.price())
    }
    pub fn get_best_ask_price(&self, now_ts: u64) -> Option<i64> {
        Some(self.asks.iter_valid(now_ts).next()?.1.price())
    }
    pub fn get_bids_size_above(&self, price: i64, max_depth: i64, now_ts: u64) -> i64 {
        let mut s = 0;
        for (_, bid) in self.bids.iter_valid(now_ts) {
            if price > bid.price() || s >= max_depth {
                break;
            }
            s += bid.quantity;
        }
        s.min(max_depth)
    }
    pub fn get_impact_price(&self, side: Side, quantity: i64, now_ts: u64) -> Option<i64> {
        let mut s = 0;
        let book_side = match side {
            Side::Bid => self.bids.iter_valid(now_ts),
            Side::Ask => self.asks.iter_valid(now_ts),
        };
        for (_, order) in book_side {
            s += order.quantity;
            if s >= quantity {
                return Some(order.price());
            }
        }
        None
    }
    pub fn get_asks_size_below(&self, price: i64, max_depth: i64, now_ts: u64) -> i64 {
        let mut s = 0;
        for (_, ask) in self.asks.iter_valid(now_ts) {
            if price < ask.price() || s >= max_depth {
                break;
            }
            s += ask.quantity;
        }
        s.min(max_depth)
    }
    pub fn get_bids_size_above_order(&self, order_id: i128, max_depth: i64, now_ts: u64) -> i64 {
        let mut s = 0;
        for (_, bid) in self.bids.iter_valid(now_ts) {
            if bid.key == order_id || s >= max_depth {
                break;
            }
            s += bid.quantity;
        }
        s.min(max_depth)
    }
    pub fn get_asks_size_below_order(&self, order_id: i128, max_depth: i64, now_ts: u64) -> i64 {
        let mut s = 0;
        for (_, ask) in self.asks.iter_valid(now_ts) {
            if ask.key == order_id || s >= max_depth {
                break;
            }
            s += ask.quantity;
        }
        s.min(max_depth)
    }
    #[inline(never)]
    pub fn new_order(
        &mut self,
        program_id: &Pubkey,
        mango_group: &MangoGroup,
        mango_group_pk: &Pubkey,
        mango_cache: &MangoCache,
        event_queue: &mut EventQueue,
        market: &mut PerpMarket,
        oracle_price: I80F48,
        mango_account: &mut MangoAccount,
        mango_account_pk: &Pubkey,
        market_index: usize,
        side: Side,
        price: i64,
        max_base_quantity: i64,
        max_quote_quantity: i64,
        order_type: OrderType,
        time_in_force: u8,
        client_order_id: u64,
        now_ts: u64,
        referrer_mango_account_ai: Option<&AccountInfo>,
        limit: u8,
    ) -> MangoResult {
        match side {
            Side::Bid => self.new_bid(
                program_id,
                mango_group,
                mango_group_pk,
                mango_cache,
                event_queue,
                market,
                oracle_price,
                mango_account,
                mango_account_pk,
                market_index,
                price,
                max_base_quantity,
                max_quote_quantity,
                order_type,
                time_in_force,
                client_order_id,
                now_ts,
                referrer_mango_account_ai,
                limit,
            ),
            Side::Ask => self.new_ask(
                program_id,
                mango_group,
                mango_group_pk,
                mango_cache,
                event_queue,
                market,
                oracle_price,
                mango_account,
                mango_account_pk,
                market_index,
                price,
                max_base_quantity,
                max_quote_quantity,
                order_type,
                time_in_force,
                client_order_id,
                now_ts,
                referrer_mango_account_ai,
                limit,
            ),
        }
    }
    pub fn sim_new_bid(
        &self,
        market: &PerpMarket,
        info: &PerpMarketInfo,
        token_info: &TokenInfo,
        oracle_price: I80F48,
        price: i64,
        max_base_quantity: i64,
        max_quote_quantity: i64,
        order_type: OrderType,
        now_ts: u64,
    ) -> MangoResult<(i64, i64, i64, i64)> {
        let (mut taker_base, mut taker_quote, mut bids_quantity, asks_quantity) = (0, 0, 0i64, 0);
        let (post_only, mut post_allowed, price) = match order_type {
            OrderType::Limit => (false, true, price),
            OrderType::ImmediateOrCancel => (false, false, price),
            OrderType::PostOnly => (true, true, price),
            OrderType::Market => (false, false, i64::MAX),
            OrderType::PostOnlySlide => {
                let price = if let Some(best_ask_price) = self.get_best_ask_price(now_ts) {
                    price.min(best_ask_price.checked_sub(1).ok_or(math_err!())?)
                } else {
                    price
                };
                (true, true, price)
            }
        };
        if post_allowed {
            let native_price = market.lot_to_native_price(price);
            if native_price > info.maint_liab_weight.checked_mul(oracle_price).unwrap() {
                if token_info.perp_market_mode.is_reduce_only() {
                    let low_threshold = market.lot_to_native_price(1);
                    if oracle_price < low_threshold && native_price > low_threshold {
                        msg!("Posting on book disallowed due to price limits");
                        post_allowed = false;
                    }
                } else {
                    msg!("Posting on book disallowed due to price limits");
                    post_allowed = false;
                }
            }
        }
        let mut rem_base_quantity = max_base_quantity;
        let mut rem_quote_quantity = max_quote_quantity;
        for (_, best_ask) in self.asks.iter_valid(now_ts) {
            let best_ask_price = best_ask.price();
            if price < best_ask_price {
                break;
            } else if post_only {
                return Ok((taker_base, taker_quote, bids_quantity, asks_quantity));
            }
            let max_match_by_quote = rem_quote_quantity / best_ask_price;
            let match_quantity = rem_base_quantity.min(best_ask.quantity).min(max_match_by_quote);
            let match_quote = match_quantity * best_ask_price;
            rem_base_quantity -= match_quantity;
            rem_quote_quantity -= match_quote;
            taker_base += match_quantity;
            taker_quote -= match_quote;
            if match_quantity == max_match_by_quote || rem_base_quantity == 0 {
                break;
            }
        }
        let book_base_quantity = rem_base_quantity.min(rem_quote_quantity / price);
        if post_allowed && book_base_quantity > 0 {
            bids_quantity = bids_quantity.checked_add(book_base_quantity).unwrap();
        }
        Ok((taker_base, taker_quote, bids_quantity, asks_quantity))
    }
    pub fn sim_new_ask(
        &self,
        market: &PerpMarket,
        info: &PerpMarketInfo,
        oracle_price: I80F48,
        price: i64,
        max_base_quantity: i64,
        max_quote_quantity: i64,
        order_type: OrderType,
        now_ts: u64,
    ) -> MangoResult<(i64, i64, i64, i64)> {
        let (mut taker_base, mut taker_quote, bids_quantity, mut asks_quantity) = (0, 0, 0, 0i64);
        let (post_only, mut post_allowed, price) = match order_type {
            OrderType::Limit => (false, true, price),
            OrderType::ImmediateOrCancel => (false, false, price),
            OrderType::PostOnly => (true, true, price),
            OrderType::Market => (false, false, 1),
            OrderType::PostOnlySlide => {
                let price = if let Some(best_bid_price) = self.get_best_bid_price(now_ts) {
                    price.max(best_bid_price.checked_add(1).ok_or(math_err!())?)
                } else {
                    price
                };
                (true, true, price)
            }
        };
        if post_allowed {
            let native_price = market.lot_to_native_price(price);
            if native_price.checked_div(oracle_price).unwrap() < info.maint_asset_weight {
                msg!("Posting on book disallowed due to price limits");
                post_allowed = false;
            }
        }
        let mut rem_base_quantity = max_base_quantity;
        let mut rem_quote_quantity = max_quote_quantity;
        for (_, best_bid) in self.bids.iter_valid(now_ts) {
            let best_bid_price = best_bid.price();
            if price > best_bid_price {
                break;
            } else if post_only {
                return Ok((taker_base, taker_quote, bids_quantity, asks_quantity));
            }
            let max_match_by_quote = rem_quote_quantity / best_bid_price;
            let match_quantity = rem_base_quantity.min(best_bid.quantity).min(max_match_by_quote);
            let match_quote = match_quantity * best_bid_price;
            rem_base_quantity -= match_quantity;
            rem_quote_quantity -= match_quote;
            taker_base -= match_quantity;
            taker_quote += match_quote;
            if match_quantity == max_match_by_quote || rem_base_quantity == 0 {
                break;
            }
        }
        let book_base_quantity = rem_base_quantity.min(rem_quote_quantity / price);
        if post_allowed && book_base_quantity > 0 {
            asks_quantity = asks_quantity.checked_add(book_base_quantity).unwrap();
        }
        Ok((taker_base, taker_quote, bids_quantity, asks_quantity))
    }
    #[inline(never)]
    fn new_bid(
        &mut self,
        program_id: &Pubkey,
        mango_group: &MangoGroup,
        mango_group_pk: &Pubkey,
        mango_cache: &MangoCache,
        event_queue: &mut EventQueue,
        market: &mut PerpMarket,
        oracle_price: I80F48,
        mango_account: &mut MangoAccount,
        mango_account_pk: &Pubkey,
        market_index: usize,
        price: i64,
        max_base_quantity: i64,
        max_quote_quantity: i64,
        order_type: OrderType,
        time_in_force: u8,
        client_order_id: u64,
        now_ts: u64,
        referrer_mango_account_ai: Option<&AccountInfo>,
        mut limit: u8,
    ) -> MangoResult {
        let (post_only, mut post_allowed, price) = match order_type {
            OrderType::Limit => (false, true, price),
            OrderType::ImmediateOrCancel => (false, false, price),
            OrderType::PostOnly => (true, true, price),
            OrderType::Market => (false, false, i64::MAX),
            OrderType::PostOnlySlide => {
                let price = if let Some(best_ask_price) = self.get_best_ask_price(now_ts) {
                    price.min(best_ask_price.checked_sub(1).ok_or(math_err!())?)
                } else {
                    price
                };
                (true, true, price)
            }
        };
        let info = &mango_group.perp_markets[market_index];
        if post_allowed {
            let native_price = market.lot_to_native_price(price);
            if native_price > info.maint_liab_weight.checked_mul(oracle_price).unwrap() {
                if mango_group.tokens[market_index].perp_market_mode.is_reduce_only() {
                    let low_threshold = market.lot_to_native_price(1);
                    if oracle_price < low_threshold && native_price > low_threshold {
                        msg!("Posting on book disallowed due to price limits");
                        post_allowed = false;
                    }
                } else {
                    msg!("Posting on book disallowed due to price limits");
                    post_allowed = false;
                }
            }
        }
        let mut ref_fee_rate = None;
        let mut referrer_mango_account_opt = None;
        let order_id = market.gen_order_id(Side::Bid, price);
        let mut rem_base_quantity = max_base_quantity;
        let mut rem_quote_quantity = max_quote_quantity;
        let mut ask_changes: Vec<(NodeHandle, i64)> = vec![];
        let mut ask_deletes: Vec<i128> = vec![];
        let mut number_of_dropped_expired_orders = 0;
        for (best_ask_h, best_ask) in self.asks.iter_all_including_invalid() {
            if !best_ask.is_valid(now_ts) {
                if number_of_dropped_expired_orders < DROP_EXPIRED_ORDER_LIMIT {
                    number_of_dropped_expired_orders += 1;
                    let event = OutEvent::new(
                        Side::Ask,
                        best_ask.owner_slot,
                        now_ts,
                        event_queue.header.seq_num,
                        best_ask.owner,
                        best_ask.quantity,
                    );
                    event_queue.push_back(cast(event)).unwrap();
                    ask_deletes.push(best_ask.key);
                }
                continue;
            }
            let best_ask_price = best_ask.price();
            if price < best_ask_price {
                break;
            } else if post_only {
                msg!("Order could not be placed due to PostOnly");
                post_allowed = false;
                break;
            } else if limit == 0 {
                msg!("Order matching limit reached");
                post_allowed = false;
                break;
            }
            let max_match_by_quote = rem_quote_quantity / best_ask_price;
            if max_match_by_quote == 0 {
                post_allowed = false;
                break;
            }
            let match_quantity = rem_base_quantity.min(best_ask.quantity).min(max_match_by_quote);
            let done = match_quantity == max_match_by_quote || match_quantity == rem_base_quantity;
            let match_quote = match_quantity * best_ask_price;
            rem_base_quantity -= match_quantity;
            rem_quote_quantity -= match_quote;
            mango_account.perp_accounts[market_index].add_taker_trade(match_quantity, -match_quote);
            let new_best_ask_quantity = best_ask.quantity - match_quantity;
            let maker_out = new_best_ask_quantity == 0;
            if maker_out {
                ask_deletes.push(best_ask.key);
            } else {
                ask_changes.push((best_ask_h, new_best_ask_quantity));
            }
            if ref_fee_rate.is_none() {
                let (a, b) = determine_ref_vars(
                    program_id,
                    mango_group,
                    mango_group_pk,
                    mango_cache,
                    mango_account,
                    referrer_mango_account_ai,
                    now_ts,
                )?;
                ref_fee_rate = Some(a);
                referrer_mango_account_opt = b;
            }
            let fill = FillEvent::new(
                Side::Bid,
                best_ask.owner_slot,
                maker_out,
                now_ts,
                event_queue.header.seq_num,
                best_ask.owner,
                best_ask.key,
                best_ask.client_order_id,
                info.maker_fee,
                best_ask.best_initial,
                best_ask.timestamp,
                *mango_account_pk,
                order_id,
                client_order_id,
                info.taker_fee + ref_fee_rate.unwrap(),
                best_ask_price,
                match_quantity,
                best_ask.version,
            );
            event_queue.push_back(cast(fill)).unwrap();
            limit -= 1;
            if done {
                break;
            }
        }
        let total_quote_taken = max_quote_quantity - rem_quote_quantity;
        for (handle, new_quantity) in ask_changes {
            self.asks.get_mut(handle).unwrap().as_leaf_mut().unwrap().quantity = new_quantity;
        }
        for key in ask_deletes {
            let _removed_leaf = self.asks.remove_by_key(key).unwrap();
        }
        let book_base_quantity = rem_base_quantity.min(rem_quote_quantity / price);
        if post_allowed && book_base_quantity > 0 {
            if let Some(expired_bid) = self.bids.remove_one_expired(now_ts) {
                let event = OutEvent::new(
                    Side::Bid,
                    expired_bid.owner_slot,
                    now_ts,
                    event_queue.header.seq_num,
                    expired_bid.owner,
                    expired_bid.quantity,
                );
                event_queue.push_back(cast(event)).unwrap();
            }
            if self.bids.is_full() {
                let min_bid = self.bids.remove_min().unwrap();
                check!(price > min_bid.price(), MangoErrorCode::OutOfSpace)?;
                let event = OutEvent::new(
                    Side::Bid,
                    min_bid.owner_slot,
                    now_ts,
                    event_queue.header.seq_num,
                    min_bid.owner,
                    min_bid.quantity,
                );
                event_queue.push_back(cast(event)).unwrap();
            }
            let best_initial = if market.meta_data.version == 0 {
                match self.get_best_bid_price(now_ts) {
                    None => price,
                    Some(p) => p,
                }
            } else {
                let max_depth: i64 = market.liquidity_mining_info.max_depth_bps.to_num();
                self.get_bids_size_above(price, max_depth, now_ts)
            };
            let owner_slot = mango_account
                .next_order_slot()
                .ok_or(throw_err!(MangoErrorCode::TooManyOpenOrders))?;
            let new_bid = LeafNode::new(
                market.meta_data.version,
                owner_slot as u8,
                order_id,
                *mango_account_pk,
                book_base_quantity,
                client_order_id,
                now_ts,
                best_initial,
                order_type,
                time_in_force,
            );
            let _result = self.bids.insert_leaf(&new_bid)?;
            msg!(
                "bid on book order_id={} quantity={} price={}",
                order_id,
                book_base_quantity,
                price
            );
            mango_account.add_order(market_index, Side::Bid, &new_bid)?;
        }
        if total_quote_taken > 0 {
            apply_fees(
                market,
                info,
                mango_account,
                mango_account_pk,
                market_index,
                referrer_mango_account_opt,
                referrer_mango_account_ai,
                total_quote_taken,
                ref_fee_rate.unwrap(),
                &mango_cache.perp_market_cache[market_index],
            );
        }
        Ok(())
    }
    #[inline(never)]
    pub fn new_ask(
        &mut self,
        program_id: &Pubkey,
        mango_group: &MangoGroup,
        mango_group_pk: &Pubkey,
        mango_cache: &MangoCache,
        event_queue: &mut EventQueue,
        market: &mut PerpMarket,
        oracle_price: I80F48,
        mango_account: &mut MangoAccount,
        mango_account_pk: &Pubkey,
        market_index: usize,
        price: i64,
        max_base_quantity: i64,
        max_quote_quantity: i64,
        order_type: OrderType,
        time_in_force: u8,
        client_order_id: u64,
        now_ts: u64,
        referrer_mango_account_ai: Option<&AccountInfo>,
        mut limit: u8,
    ) -> MangoResult {
        let (post_only, mut post_allowed, price) = match order_type {
            OrderType::Limit => (false, true, price),
            OrderType::ImmediateOrCancel => (false, false, price),
            OrderType::PostOnly => (true, true, price),
            OrderType::Market => (false, false, 1),
            OrderType::PostOnlySlide => {
                let price = if let Some(best_bid_price) = self.get_best_bid_price(now_ts) {
                    price.max(best_bid_price.checked_add(1).ok_or(math_err!())?)
                } else {
                    price
                };
                (true, true, price)
            }
        };
        let info = &mango_group.perp_markets[market_index];
        if post_allowed {
            let native_price = market.lot_to_native_price(price);
            if native_price.checked_div(oracle_price).unwrap() < info.maint_asset_weight {
                msg!("Posting on book disallowed due to price limits");
                post_allowed = false;
            }
        }
        let mut ref_fee_rate = None;
        let mut referrer_mango_account_opt = None;
        let order_id = market.gen_order_id(Side::Ask, price);
        let mut rem_base_quantity = max_base_quantity;
        let mut rem_quote_quantity = max_quote_quantity;
        let mut bid_changes: Vec<(NodeHandle, i64)> = vec![];
        let mut bid_deletes: Vec<i128> = vec![];
        let mut number_of_dropped_expired_orders = 0;
        for (best_bid_h, best_bid) in self.bids.iter_all_including_invalid() {
            if !best_bid.is_valid(now_ts) {
                if number_of_dropped_expired_orders < DROP_EXPIRED_ORDER_LIMIT {
                    number_of_dropped_expired_orders += 1;
                    let event = OutEvent::new(
                        Side::Bid,
                        best_bid.owner_slot,
                        now_ts,
                        event_queue.header.seq_num,
                        best_bid.owner,
                        best_bid.quantity,
                    );
                    event_queue.push_back(cast(event)).unwrap();
                    bid_deletes.push(best_bid.key);
                }
                continue;
            }
            let best_bid_price = best_bid.price();
            if price > best_bid_price {
                break;
            } else if post_only {
                msg!("Order could not be placed due to PostOnly");
                post_allowed = false;
                break;
            } else if limit == 0 {
                msg!("Order matching limit reached");
                post_allowed = false;
                break;
            }
            let max_match_by_quote = rem_quote_quantity / best_bid_price;
            if max_match_by_quote == 0 {
                post_allowed = false;
                break;
            }
            let match_quantity = rem_base_quantity.min(best_bid.quantity).min(max_match_by_quote);
            let done = match_quantity == max_match_by_quote || match_quantity == rem_base_quantity;
            let match_quote = match_quantity * best_bid_price;
            rem_base_quantity -= match_quantity;
            rem_quote_quantity -= match_quote;
            mango_account.perp_accounts[market_index].add_taker_trade(-match_quantity, match_quote);
            let new_best_bid_quantity = best_bid.quantity - match_quantity;
            let maker_out = new_best_bid_quantity == 0;
            if maker_out {
                bid_deletes.push(best_bid.key);
            } else {
                bid_changes.push((best_bid_h, new_best_bid_quantity));
            }
            if ref_fee_rate.is_none() {
                let (a, b) = determine_ref_vars(
                    program_id,
                    mango_group,
                    mango_group_pk,
                    mango_cache,
                    mango_account,
                    referrer_mango_account_ai,
                    now_ts,
                )?;
                ref_fee_rate = Some(a);
                referrer_mango_account_opt = b;
            }
            let fill = FillEvent::new(
                Side::Ask,
                best_bid.owner_slot,
                maker_out,
                now_ts,
                event_queue.header.seq_num,
                best_bid.owner,
                best_bid.key,
                best_bid.client_order_id,
                info.maker_fee,
                best_bid.best_initial,
                best_bid.timestamp,
                *mango_account_pk,
                order_id,
                client_order_id,
                info.taker_fee + ref_fee_rate.unwrap(),
                best_bid_price,
                match_quantity,
                best_bid.version,
            );
            event_queue.push_back(cast(fill)).unwrap();
            limit -= 1;
            if done {
                break;
            }
        }
        let total_quote_taken = max_quote_quantity - rem_quote_quantity;
        for (handle, new_quantity) in bid_changes {
            self.bids.get_mut(handle).unwrap().as_leaf_mut().unwrap().quantity = new_quantity;
        }
        for key in bid_deletes {
            let _removed_leaf = self.bids.remove_by_key(key).unwrap();
        }
        let book_base_quantity = rem_base_quantity.min(rem_quote_quantity / price);
        if book_base_quantity > 0 && post_allowed {
            if let Some(expired_ask) = self.asks.remove_one_expired(now_ts) {
                let event = OutEvent::new(
                    Side::Ask,
                    expired_ask.owner_slot,
                    now_ts,
                    event_queue.header.seq_num,
                    expired_ask.owner,
                    expired_ask.quantity,
                );
                event_queue.push_back(cast(event)).unwrap();
            }
            if self.asks.is_full() {
                let max_ask = self.asks.remove_max().unwrap();
                check!(price < max_ask.price(), MangoErrorCode::OutOfSpace)?;
                let event = OutEvent::new(
                    Side::Ask,
                    max_ask.owner_slot,
                    now_ts,
                    event_queue.header.seq_num,
                    max_ask.owner,
                    max_ask.quantity,
                );
                event_queue.push_back(cast(event)).unwrap();
            }
            let best_initial = if market.meta_data.version == 0 {
                match self.get_best_ask_price(now_ts) {
                    None => price,
                    Some(p) => p,
                }
            } else {
                let max_depth: i64 = market.liquidity_mining_info.max_depth_bps.to_num();
                self.get_asks_size_below(price, max_depth, now_ts)
            };
            let owner_slot = mango_account
                .next_order_slot()
                .ok_or(throw_err!(MangoErrorCode::TooManyOpenOrders))?;
            let new_ask = LeafNode::new(
                market.meta_data.version,
                owner_slot as u8,
                order_id,
                *mango_account_pk,
                book_base_quantity,
                client_order_id,
                now_ts,
                best_initial,
                order_type,
                time_in_force,
            );
            let _result = self.asks.insert_leaf(&new_ask)?;
            msg!(
                "ask on book order_id={} quantity={} price={}",
                order_id,
                book_base_quantity,
                price
            );
            mango_account.add_order(market_index, Side::Ask, &new_ask)?;
        }
        if total_quote_taken > 0 {
            apply_fees(
                market,
                info,
                mango_account,
                mango_account_pk,
                market_index,
                referrer_mango_account_opt,
                referrer_mango_account_ai,
                total_quote_taken,
                ref_fee_rate.unwrap(),
                &mango_cache.perp_market_cache[market_index],
            );
        }
        Ok(())
    }
    pub fn cancel_order(&mut self, order_id: i128, side: Side) -> MangoResult<LeafNode> {
        match side {
            Side::Bid => {
                self.bids.remove_by_key(order_id).ok_or(throw_err!(MangoErrorCode::InvalidOrderId))
            }
            Side::Ask => {
                self.asks.remove_by_key(order_id).ok_or(throw_err!(MangoErrorCode::InvalidOrderId))
            }
        }
    }
    pub fn cancel_all(
        &mut self,
        mango_account: &mut MangoAccount,
        market_index: usize,
        mut limit: u8,
    ) -> MangoResult {
        let market_index = market_index as u8;
        for i in 0..MAX_PERP_OPEN_ORDERS {
            if mango_account.order_market[i] != market_index {
                continue;
            }
            let order_id = mango_account.orders[i];
            match self.cancel_order(order_id, mango_account.order_side[i]) {
                Ok(order) => {
                    mango_account.remove_order(order.owner_slot as usize, order.quantity)?;
                }
                Err(_) => {
                }
            };
            limit -= 1;
            if limit == 0 {
                break;
            }
        }
        Ok(())
    }
    pub fn cancel_all_side_with_size_incentives(
        &mut self,
        mango_account: &mut MangoAccount,
        perp_market: &mut PerpMarket,
        market_index: usize,
        side: Side,
        mut limit: u8,
    ) -> MangoResult<(Vec<i128>, Vec<i128>)> {
        let now_ts = Clock::get()?.unix_timestamp as u64;
        let max_depth: i64 = perp_market.liquidity_mining_info.max_depth_bps.to_num();
        let mut all_order_ids = vec![];
        let mut canceled_order_ids = vec![];
        let mut keys = vec![];
        let market_index_u8 = market_index as u8;
        for i in 0..MAX_PERP_OPEN_ORDERS {
            if mango_account.order_market[i] == market_index_u8
                && mango_account.order_side[i] == side
            {
                all_order_ids.push(mango_account.orders[i]);
                keys.push(mango_account.orders[i])
            }
        }
        match side {
            Side::Bid => self.cancel_all_bids_with_size_incentives(
                mango_account,
                perp_market,
                market_index,
                max_depth,
                now_ts,
                &mut limit,
                keys,
                &mut canceled_order_ids,
            )?,
            Side::Ask => self.cancel_all_asks_with_size_incentives(
                mango_account,
                perp_market,
                market_index,
                max_depth,
                now_ts,
                &mut limit,
                keys,
                &mut canceled_order_ids,
            )?,
        };
        Ok((all_order_ids, canceled_order_ids))
    }
    pub fn cancel_all_with_size_incentives(
        &mut self,
        mango_account: &mut MangoAccount,
        perp_market: &mut PerpMarket,
        market_index: usize,
        mut limit: u8,
    ) -> MangoResult<(Vec<i128>, Vec<i128>)> {
        let now_ts = Clock::get()?.unix_timestamp as u64;
        let max_depth: i64 = perp_market.liquidity_mining_info.max_depth_bps.to_num();
        let mut all_order_ids = vec![];
        let mut canceled_order_ids = vec![];
        let market_index_u8 = market_index as u8;
        let mut bids_keys = vec![];
        let mut asks_keys = vec![];
        for i in 0..MAX_PERP_OPEN_ORDERS {
            if mango_account.order_market[i] != market_index_u8 {
                continue;
            }
            all_order_ids.push(mango_account.orders[i]);
            match mango_account.order_side[i] {
                Side::Bid => bids_keys.push(mango_account.orders[i]),
                Side::Ask => asks_keys.push(mango_account.orders[i]),
            }
        }
        self.cancel_all_bids_with_size_incentives(
            mango_account,
            perp_market,
            market_index,
            max_depth,
            now_ts,
            &mut limit,
            bids_keys,
            &mut canceled_order_ids,
        )?;
        self.cancel_all_asks_with_size_incentives(
            mango_account,
            perp_market,
            market_index,
            max_depth,
            now_ts,
            &mut limit,
            asks_keys,
            &mut canceled_order_ids,
        )?;
        Ok((all_order_ids, canceled_order_ids))
    }
    fn cancel_all_bids_with_size_incentives(
        &mut self,
        mango_account: &mut MangoAccount,
        perp_market: &mut PerpMarket,
        market_index: usize,
        max_depth: i64,
        now_ts: u64,
        limit: &mut u8,
        mut my_bids: Vec<i128>,
        canceled_order_ids: &mut Vec<i128>,
    ) -> MangoResult {
        my_bids.sort_unstable();
        let mut bids_and_sizes = vec![];
        let mut cuml_bids = 0;
        let mut iter = self.bids.iter_all_including_invalid();
        let mut curr = iter.next();
        while let Some((_, bid)) = curr {
            match my_bids.last() {
                None => break,
                Some(&my_highest_bid) => {
                    if bid.key > my_highest_bid {
                        if bid.is_valid(now_ts) {
                            cuml_bids += bid.quantity;
                        }
                        curr = iter.next();
                    } else if bid.key == my_highest_bid {
                        bids_and_sizes.push((bid.key, cuml_bids));
                        my_bids.pop();
                        curr = iter.next();
                    } else {
                        my_bids.pop();
                    }
                    if cuml_bids >= max_depth {
                        for bid_key in my_bids {
                            bids_and_sizes.push((bid_key, max_depth));
                        }
                        break;
                    }
                }
            }
        }
        for (key, cuml_size) in bids_and_sizes {
            if *limit == 0 {
                return Ok(());
            } else {
                *limit -= 1;
            }
            match self.cancel_order(key, Side::Bid) {
                Ok(order) => {
                    mango_account.remove_order(order.owner_slot as usize, order.quantity)?;
                    canceled_order_ids.push(key);
                    if order.version == perp_market.meta_data.version
                        && order.version != 0
                        && order.is_valid(now_ts)
                    {
                        mango_account.perp_accounts[market_index].apply_size_incentives(
                            perp_market,
                            order.best_initial,
                            cuml_size,
                            order.timestamp,
                            now_ts,
                            order.quantity,
                        )?;
                    }
                }
                Err(_) => {
                    msg!("Failed to cancel bid oid: {}; Either error state or bid is on EventQueue unprocessed", key)
                }
            }
        }
        Ok(())
    }
    fn cancel_all_asks_with_size_incentives(
        &mut self,
        mango_account: &mut MangoAccount,
        perp_market: &mut PerpMarket,
        market_index: usize,
        max_depth: i64,
        now_ts: u64,
        limit: &mut u8,
        mut my_asks: Vec<i128>,
        canceled_order_ids: &mut Vec<i128>,
    ) -> MangoResult {
        my_asks.sort_unstable_by(|a, b| b.cmp(a));
        let mut asks_and_sizes = vec![];
        let mut cuml_asks = 0;
        let mut iter = self.asks.iter_all_including_invalid();
        let mut curr = iter.next();
        while let Some((_, ask)) = curr {
            match my_asks.last() {
                None => break,
                Some(&my_lowest_ask) => {
                    if ask.key < my_lowest_ask {
                        if ask.is_valid(now_ts) {
                            cuml_asks += ask.quantity;
                        }
                        curr = iter.next();
                    } else if ask.key == my_lowest_ask {
                        asks_and_sizes.push((ask.key, cuml_asks));
                        my_asks.pop();
                        curr = iter.next();
                    } else {
                        my_asks.pop();
                    }
                    if cuml_asks >= max_depth {
                        for key in my_asks {
                            asks_and_sizes.push((key, max_depth))
                        }
                        break;
                    }
                }
            }
        }
        for (key, cuml_size) in asks_and_sizes {
            if *limit == 0 {
                return Ok(());
            } else {
                *limit -= 1;
            }
            match self.cancel_order(key, Side::Ask) {
                Ok(order) => {
                    mango_account.remove_order(order.owner_slot as usize, order.quantity)?;
                    canceled_order_ids.push(key);
                    if order.version == perp_market.meta_data.version
                        && order.version != 0
                        && order.is_valid(now_ts)
                    {
                        mango_account.perp_accounts[market_index].apply_size_incentives(
                            perp_market,
                            order.best_initial,
                            cuml_size,
                            order.timestamp,
                            now_ts,
                            order.quantity,
                        )?;
                    }
                }
                Err(_) => {
                    msg!("Failed to cancel ask oid: {}; Either error state or ask is on EventQueue unprocessed", key);
                }
            }
        }
        Ok(())
    }
    pub fn cancel_all_with_price_incentives(
        &mut self,
        mango_account: &mut MangoAccount,
        perp_market: &mut PerpMarket,
        market_index: usize,
        mut limit: u8,
    ) -> MangoResult {
        let now_ts = Clock::get()?.unix_timestamp as u64;
        for i in 0..MAX_PERP_OPEN_ORDERS {
            if mango_account.order_market[i] != market_index as u8 {
                continue;
            }
            let order_id = mango_account.orders[i];
            let order_side = mango_account.order_side[i];
            let best_final = match order_side {
                Side::Bid => self.get_best_bid_price(now_ts).unwrap(),
                Side::Ask => self.get_best_ask_price(now_ts).unwrap(),
            };
            match self.cancel_order(order_id, order_side) {
                Ok(order) => {
                    mango_account.remove_order(order.owner_slot as usize, order.quantity)?;
                    if order.version != perp_market.meta_data.version {
                        continue;
                    }
                    mango_account.perp_accounts[market_index].apply_price_incentives(
                        perp_market,
                        order_side,
                        order.price(),
                        order.best_initial,
                        best_final,
                        order.timestamp,
                        now_ts,
                        order.quantity,
                    )?;
                }
                Err(_) => {
                }
            };
            limit -= 1;
            if limit == 0 {
                break;
            }
        }
        Ok(())
    }
}
fn determine_ref_vars<'a>(
    program_id: &Pubkey,
    mango_group: &MangoGroup,
    mango_group_pk: &Pubkey,
    mango_cache: &MangoCache,
    mango_account: &MangoAccount,
    referrer_mango_account_ai: Option<&'a AccountInfo>,
    now_ts: u64,
) -> MangoResult<(I80F48, Option<RefMut<'a, MangoAccount>>)> {
    let mngo_index = match mango_group.find_token_index(&mngo_token::id()) {
        None => return Ok((ZERO_I80F48, None)),
        Some(i) => i,
    };
    let mngo_cache = &mango_cache.root_bank_cache[mngo_index];
    let tier_2_enabled = mango_group.ref_surcharge_centibps_tier_2 != 0
        && mango_group.ref_share_centibps_tier_2 != 0;
    let mngo_deposits = mango_account.get_native_deposit(mngo_cache, mngo_index)?;
    let ref_mngo_req = I80F48::from_num(mango_group.ref_mngo_required);
    let ref_mngo_tier_2_factor = I80F48::from_num(mango_group.ref_mngo_tier_2_factor);
    if tier_2_enabled && mngo_deposits >= ref_mngo_req * ref_mngo_tier_2_factor
        || !tier_2_enabled && mngo_deposits >= ref_mngo_req
    {
        return Ok((ZERO_I80F48, None));
    } else if tier_2_enabled && mngo_deposits >= ref_mngo_req {
        return Ok((
            I80F48::from_num(mango_group.ref_surcharge_centibps_tier_1) / CENTIBPS_PER_UNIT,
            None,
        ));
    } else if let Some(referrer_mango_account_ai) = referrer_mango_account_ai {
        if let Ok(referrer_mango_account) =
            MangoAccount::load_mut_checked(referrer_mango_account_ai, program_id, mango_group_pk)
        {
            mngo_cache.check_valid(mango_group, now_ts)?;
            let ref_mngo_deposits =
                referrer_mango_account.get_native_deposit(mngo_cache, mngo_index)?;
            let share =
                if tier_2_enabled && ref_mngo_deposits >= ref_mngo_req * ref_mngo_tier_2_factor {
                    mango_group.ref_share_centibps_tier_2.into()
                } else {
                    mango_group.ref_share_centibps_tier_1
                };
            if !referrer_mango_account.is_bankrupt
                && !referrer_mango_account.being_liquidated
                && ref_mngo_deposits >= ref_mngo_req
            {
                return Ok((
                    I80F48::from_num(share) / CENTIBPS_PER_UNIT,
                    Some(referrer_mango_account),
                ));
            }
        }
    }
    let surcharge = if tier_2_enabled {
        mango_group.ref_surcharge_centibps_tier_2.into()
    } else {
        mango_group.ref_surcharge_centibps_tier_1
    };
    Ok((I80F48::from_num(surcharge) / CENTIBPS_PER_UNIT, None))
}
fn apply_fees(
    market: &mut PerpMarket,
    info: &PerpMarketInfo,
    mango_account: &mut MangoAccount,
    mango_account_pk: &Pubkey,
    market_index: usize,
    referrer_mango_account_opt: Option<RefMut<MangoAccount>>,
    referrer_mango_account_ai: Option<&AccountInfo>,
    total_quote_taken: i64,
    ref_fee_rate: I80F48,
    perp_market_cache: &PerpMarketCache,
) {
    let taker_quote_native =
        I80F48::from_num(market.quote_lot_size.checked_mul(total_quote_taken).unwrap());
    if ref_fee_rate > ZERO_I80F48 {
        let ref_fees = taker_quote_native * ref_fee_rate;
        if let Some(mut referrer_mango_account) = referrer_mango_account_opt {
            mango_account.perp_accounts[market_index].transfer_quote_position(
                &mut referrer_mango_account.perp_accounts[market_index],
                ref_fees,
            );
            emit_perp_balances(
                referrer_mango_account.mango_group,
                *referrer_mango_account_ai.unwrap().key,
                market_index as u64,
                &referrer_mango_account.perp_accounts[market_index],
                perp_market_cache,
            );
            mango_emit_stack::<_, 200>(ReferralFeeAccrualLog {
                mango_group: referrer_mango_account.mango_group,
                referrer_mango_account: *referrer_mango_account_ai.unwrap().key,
                referree_mango_account: *mango_account_pk,
                market_index: market_index as u64,
                referral_fee_accrual: ref_fees.to_bits(),
            });
        } else {
            mango_account.perp_accounts[market_index].quote_position -= ref_fees;
            market.fees_accrued += ref_fees;
        }
    }
    let maker_fees = taker_quote_native * info.maker_fee;
    let taker_fees = taker_quote_native * info.taker_fee;
    mango_account.perp_accounts[market_index].quote_position -= taker_fees;
    market.fees_accrued += taker_fees + maker_fees;
    emit_perp_balances(
        mango_account.mango_group,
        *mango_account_pk,
        market_index as u64,
        &mango_account.perp_accounts[market_index],
        perp_market_cache,
    )
}