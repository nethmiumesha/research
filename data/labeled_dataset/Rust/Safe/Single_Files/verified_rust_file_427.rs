use std::{any::Any, fmt::Display, ops::Index};
use hashbrown::{HashMap, HashSet};
use log::{debug, warn};
use regex::Regex;
use rustc_hir::{def::DefKind, def_id::DefId};
use rustc_middle::{
    mir::{
        traversal::reverse_postorder, BasicBlock, BinOp, Body, Local, Operand, Place, PlaceRef,
        Rvalue, SourceInfo, Statement, StatementKind, Terminator, TerminatorKind, ProjectionElem,
    },
    ty::{subst::GenericArgKind, Instance, ParamEnv, Ty, TyCtxt, TyKind, TyS, relate::TypeRelation},
};
use crate::{
    dd::{self, DataDepsGraph, ASSERT_MACRO_FILTER},
    reporter::{IntegerCveType, Report},
    source_info,
};
pub const ENTRY: &'static str = ".*(::)?entrypoint";
pub fn find_entry<'tcx>(tcx: TyCtxt<'tcx>) -> Option<DefId> {
    let re = Regex::new(ENTRY).unwrap();
    for key in tcx.mir_keys(()) {
        let def_id = key.to_def_id();
        if re.is_match(tcx.def_path_str(def_id).as_str()) {
            if let DefKind::Fn | DefKind::AssocFn = tcx.def_kind(def_id) {
                if tcx.is_mir_available(def_id) {
                    return Some(def_id);
                }
            }
        }
    }
    None
}
#[derive(Debug, Hash, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct FullPlaceRef<'tcx> {
    pub func: DefId,
    pub place: PlaceRef<'tcx>,
}
impl<'tcx> FullPlaceRef<'tcx> {
    pub fn new(def_id: DefId, place: PlaceRef<'tcx>) -> Self {
        Self {
            func: def_id,
            place,
        }
    }
}
impl<'tcx> Display for FullPlaceRef<'tcx> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "FullPlaceRef({:?}, {:?})", self.func, self.place)
    }
}
pub trait StateTransitor<'tcx>: Sized + Clone + core::fmt::Debug {
    fn compute_rvalue(
        rvalue: &Rvalue<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: SourceInfo,
    ) -> Self;
    fn compute_operand(
        op: &Operand<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: SourceInfo,
    ) -> Self;
    fn compute_place(
        place: PlaceRef<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: Option<SourceInfo>,
    ) -> Self;
    fn init_place(
        place: PlaceRef<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
    ) -> Self;
    fn merge(
        &self,
        other: Self,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
    ) -> Self;
    fn compute_terminator(
        terminator: &Terminator<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: SourceInfo,
    ) -> Self;
    fn is_interesting_fn(
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>
    ) -> bool {
        true
    }
    fn compute_func(
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
    ) -> Option<Self> {
        None
    }
    fn report_func(
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        state: Self,
        sm: &mut StateMachine<'tcx, Self>
    ) {
    }
}
#[derive(Clone, Copy, Debug)]
pub struct NoopStateTransitor();
impl<'tcx> StateTransitor<'tcx> for NoopStateTransitor {
    fn compute_rvalue(
        _rvalue: &Rvalue<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: SourceInfo,
    ) -> Self {
        Self()
    }
    fn compute_operand(
        _op: &Operand<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: SourceInfo,
    ) -> Self {
        Self()
    }
    fn compute_place(
        place: PlaceRef<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: Option<SourceInfo>,
    ) -> Self {
        Self()
    }
    fn init_place(
        place: PlaceRef<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
    ) -> Self {
        Self()
    }
    fn merge(
        &self,
        other: Self,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
    ) -> Self {
        Self()
    }
    fn compute_terminator(
        terminator: &Terminator<'tcx>,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
        sm: &mut StateMachine<'tcx, Self>,
        src_info: SourceInfo,
    ) -> Self {
        Self()
    }
}
#[derive(Debug, Default)]
pub struct StateMachine<'tcx, T: StateTransitor<'tcx>> {
    states: HashMap<FullPlaceRef<'tcx>, T>,
    func_states: HashMap<DefId, T>,
    call_stack: Vec<DefId>,
}
impl<'tcx, T: StateTransitor<'tcx>> StateMachine<'tcx, T> {
    pub fn new() -> Self {
        Self {
            states: HashMap::new(),
            func_states: HashMap::new(),
            call_stack: Vec::new(),
        }
    }
    pub fn get_call_stack(&self) -> &[DefId] {
        self.call_stack.as_slice()
    }
    pub fn enter_func(&mut self, new_func: DefId) -> bool {
        if self.call_stack.contains(&new_func) {
            return false;
        }
        self.call_stack.push(new_func);
        true
    }
    pub fn exit_cur_func(&mut self) {
        self.call_stack.pop().unwrap();
    }
    pub fn update(&mut self, place: PlaceRef<'tcx>, t: T, body: &Body<'tcx>, tcx: TyCtxt<'tcx>) {
        let full_place = FullPlaceRef::new(self.get_cur_func(), place);
        self.update_full(full_place, t, body, tcx);
    }
    pub fn update_full(
        &mut self,
        full_place: FullPlaceRef<'tcx>,
        t: T,
        body: &Body<'tcx>,
        tcx: TyCtxt<'tcx>,
    ) {
        if let Some(old_st) = self.get_state(full_place).map(|s| s.clone()) {
            let st = old_st.merge(t, body, tcx, self);
            self.states.insert(full_place, st);
        } else {
            self.states.insert(full_place, t);
        }
    }
    pub fn init(&mut self, place: PlaceRef<'tcx>, body: &Body<'tcx>, tcx: TyCtxt<'tcx>) {
        let st = T::init_place(place, body, tcx, self);
        self.update(place, st, body, tcx);
    }
    #[allow(unused)]
    pub fn get_cur_func(&self) -> DefId {
        *self.call_stack.last().unwrap()
    }
    pub fn get_cur_func_state(&self) -> Option<&T> {
        self.func_states.get(&self.get_cur_func())
    }
    pub fn get_func_state(&self, def_id: DefId) -> Option<&T> {
        self.func_states.get(&def_id)
    }
    pub fn set_func_state(&mut self, def_id: DefId, t: T) {
        self.func_states.insert(def_id, t);
    }
    #[allow(unused)]
    pub fn get_state(&self, place: FullPlaceRef<'tcx>) -> Option<&T> {
        self.states.get(&place)
    }
}
pub struct WholeProgramTraverser<'tcx, T: StateTransitor<'tcx>> {
    tcx: TyCtxt<'tcx>,
    pub sm: StateMachine<'tcx, T>,
    visited: HashSet<DefId>,
}
impl<'tcx, T: StateTransitor<'tcx>> WholeProgramTraverser<'tcx, T> {
    pub fn new(tcx: TyCtxt<'tcx>) -> Self {
        Self {
            tcx,
            sm: StateMachine::new(),
            visited: HashSet::default(),
        }
    }
    pub fn start(&mut self) {
        debug!("start traversing");
        Report::reset_filter();
        if let Some(entry) = find_entry(self.tcx) {
            debug!("entry point: {:?}", entry);
            self.visited.insert(entry);
            let body = self.tcx.optimized_mir(entry);
            if let Some(func_t) = T::compute_func(body, self.tcx, &mut self.sm) {
                self.sm.set_func_state(entry, func_t);
            }
            self.process_func(body);
        }
    }
    #[allow(unused)]
    pub fn summary(&self) {
        debug!("Summary:");
        for (place, st) in self.sm.states.iter() {
            debug!("Place: {:?}, state: {:?}", place, st);
        }
    }
    pub fn check_func(&mut self, body: &Body<'tcx>) {
        if let Some(func_st) = self.sm.get_func_state(body.source.def_id()) {
            T::report_func(body, self.tcx, func_st.clone(), &mut self.sm);
        }
    }
    pub fn process_func(&mut self, body: &Body<'tcx>) {
        let func = body.source.def_id();
        if !self.sm.enter_func(body.source.def_id()) {
            return;
        }
        debug!("Process func:\t\t{:?}", self.tcx.def_path_str(func));
        let heuristic = ASSERT_MACRO_FILTER.clone();
        let ddg = dd::DataDepsGraph::new(body, self.tcx, heuristic);
        for (_bb, bb_data) in reverse_postorder(body) {
            for stmt in bb_data.statements.iter() {
                self.process_stmt(stmt, body, &ddg);
            }
            if let Some(terminator) = &bb_data.terminator {
                self.process_terminator(&terminator, body, &ddg);
            }
        }
        debug!("Exit process func:\t\"{}\"", self.tcx.def_path_str(func));
        self.sm.exit_cur_func();
    }
    fn process_stmt(&mut self, stmt: &Statement<'tcx>, body: &Body<'tcx>, ddg: &DataDepsGraph) {
        if let StatementKind::Assign(box (place, right)) = &stmt.kind {
            let state = T::compute_rvalue(right, body, self.tcx, &mut self.sm, stmt.source_info);
            self.sm.update(place.as_ref(), state, body, self.tcx);
        }
    }
    fn process_terminator(
        &mut self,
        terminator: &Terminator<'tcx>,
        body: &Body<'tcx>,
        _ddg: &DataDepsGraph,
    ) {
        match &terminator.kind {
            TerminatorKind::Call {
                func,
                args,
                destination,
                ..
            } => {
                if let Some(callee) = self.resolve_call_target(func, body) {
                    let st = T::compute_terminator(
                        terminator,
                        body,
                        self.tcx,
                        &mut self.sm,
                        terminator.source_info,
                    );
                    if let Some(dest) = destination {
                        self.sm.update(dest.0.as_ref(), st, body, self.tcx);
                    }
                    if self.process_special_calls(callee) {
                        return;
                    }
                        if self.tcx.is_mir_available(callee) {
                            let callee_body = self.tcx.optimized_mir(callee);
                            if let Some(func_t) = T::compute_func(callee_body, self.tcx, &mut self.sm) {
                                self.sm.set_func_state(callee, func_t);
                            }
                            self.process_arg_binding(args, body, callee_body, terminator.source_info);
                            self.process_func(callee_body);
                            self.process_ret_binding(destination.as_ref(), body, callee_body);
                            self.check_func(callee_body);
                        } else {
                            warn!("MIR unavailable: {}", self.tcx.def_path_str(callee));
                        }
                }
            }
            TerminatorKind::SwitchInt { discr, targets, .. } => {}
            _ => {}
        }
    }
    fn process_ret_binding(
        &mut self,
        destination: Option<&(Place<'tcx>, BasicBlock)>,
        body: &Body<'tcx>,
        callee_body: &Body<'tcx>,
    ) {
        let ret = Place::from(Local::from(0usize)).as_ref();
        let full_ret = FullPlaceRef::new(callee_body.source.def_id(), ret);
        let st = self.sm.get_state(full_ret).map(|e| e.clone());
        if let Some(st) = st {
            if let Some(destination) = destination {
                let full_dest = FullPlaceRef::new(body.source.def_id(), destination.0.as_ref());
                self.sm.update_full(full_dest, st, callee_body, self.tcx)
            }
        }
    }
    fn process_arg_binding(
        &mut self,
        args: &Vec<Operand<'tcx>>,
        body: &Body<'tcx>,
        callee_body: &Body<'tcx>,
        src_info: SourceInfo,
    ) {
        if self.tcx.type_of(callee_body.source.def_id()).is_closure() {
            let mut args: Vec<&Operand<'tcx>> = args.iter().collect();
            let st = T::compute_operand(args[0], body, self.tcx, &mut self.sm, src_info);
            let param = Place::from(Local::from(1usize)).as_ref();
            self.sm.update_full(
                FullPlaceRef::new(callee_body.source.def_id(), param),
                st,
                callee_body,
                self.tcx
            );
            let mut rest_args = Vec::new();
            let closure_arg = args.pop().unwrap();
            let closure_args_ty: Vec<Ty<'tcx>> = closure_arg.ty(body, self.tcx).tuple_fields().collect();
            let closure_args_cnt = callee_body.arg_count - args.len();
            let closure_arg_place = closure_arg.place().unwrap();
            for i in 0..closure_args_cnt {
                let arg = Place {
                    local: closure_arg_place.local,
                    projection: self.tcx.intern_place_elems(&[ProjectionElem::Field(i.into(), closure_args_ty[i])]),
                };
                rest_args.push(arg);
            }
            for (arg_i, rest_arg) in rest_args.iter().enumerate() {
                let st = T::compute_place(rest_arg.as_ref(), body, self.tcx, &mut self.sm, Some(src_info));
                let param = Place::from(Local::from(1 + arg_i)).as_ref();
                self.sm.update_full(
                    FullPlaceRef::new(callee_body.source.def_id(), param),
                    st,
                    callee_body,
                    self.tcx,
                );
            }
        } else {
            assert_eq!(args.len(), callee_body.arg_count);
            for (arg_i, arg) in args.iter().enumerate() {
                let st = T::compute_operand(arg, body, self.tcx, &mut self.sm, src_info);
                let param = Place::from(Local::from(1 + arg_i)).as_ref();
                self.sm.update_full(
                    FullPlaceRef::new(callee_body.source.def_id(), param),
                    st,
                    callee_body,
                    self.tcx,
                );
            }
        }
    }
    fn process_special_calls(&mut self, callee: DefId) -> bool {
        const BLACKLIST: &'static [&'static str] = &[
            "std::.*",
            "core::*",
            "alloc::.*",
            "anchor_lang::.*",
            "curve25519_dalek::.*",
        ];
        const WHITELIST: &'static [&'static str] = &[".*::try_accounts", ".*::try_from"];
        let name = self.tcx.def_path_str(callee);
        for item in WHITELIST {
            let re = Regex::new(item).unwrap();
            if re.is_match(name.as_str()) {
                return false;
            }
        }
        for item in BLACKLIST {
            let re = Regex::new(item).unwrap();
            if re.is_match(name.as_str()) {
                return true;
            }
        }
        false
    }
    fn resolve_call_target(&self, func: &Operand<'tcx>, body: &Body<'tcx>) -> Option<DefId> {
        match func {
            Operand::Copy(target) | Operand::Move(target) => {
                warn!(
                    "Failed to found callee target for {:?} in function {:?}",
                    func,
                    self.sm.get_cur_func()
                );
                None
            }
            Operand::Constant(box c) => {
                match c.ty().kind() {
                    TyKind::FnDef(callee_def_id, substs) => {
                        let instance = Instance::resolve(
                            self.tcx,
                            self.tcx.param_env(body.source.def_id()).with_reveal_all_normalized(self.tcx),
                            *callee_def_id,
                            substs,
                        )
                        .ok()??;
                        Some(instance.def_id())
                    }
                    TyKind::Closure(callee_def_id, _substs) => {
                        Some(*callee_def_id)
                    },
                    _ => None,
                }
            }
        }
    }
}