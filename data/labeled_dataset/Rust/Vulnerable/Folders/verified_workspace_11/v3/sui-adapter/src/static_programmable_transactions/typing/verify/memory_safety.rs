use std::{
    cell::OnceCell,
    collections::{BTreeMap, BTreeSet},
    fmt,
};
use crate::{
    sp,
    static_programmable_transactions::{
        env::Env,
        typing::ast::{self as T, Type},
    },
};
use move_regex_borrow_graph::{MeterError, meter::DummyMeter, references::Ref};
use sui_types::{
    error::{ExecutionError, SafeIndex, command_argument_error},
    execution_status::CommandArgumentError,
};
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Debug)]
struct Location(T::Location);
type Graph = move_regex_borrow_graph::collections::Graph<(), Location>;
type Paths = move_regex_borrow_graph::collections::Paths<(), Location>;
#[must_use]
enum Value {
    Ref(Ref),
    NonRef,
}
struct Context {
    graph: Graph,
    local_root: Ref,
    tx_context: Option<Value>,
    gas_coin: Option<Value>,
    objects: Vec<Option<Value>>,
    withdrawals: Vec<Option<Value>>,
    pure: Vec<Option<Value>>,
    receiving: Vec<Option<Value>>,
    results: Vec<Vec<Option<Value>>>,
}
impl Value {
    fn is_ref(&self) -> bool {
        match self {
            Value::Ref(_) => true,
            Value::NonRef => false,
        }
    }
    fn is_non_ref(&self) -> bool {
        match self {
            Value::Ref(_) => false,
            Value::NonRef => true,
        }
    }
    fn to_ref(&self) -> Option<Ref> {
        match self {
            Value::Ref(r) => Some(*r),
            Value::NonRef => None,
        }
    }
}
impl Context {
    fn new(env: &Env, ast: &T::Transaction) -> Result<Self, ExecutionError> {
        let gas_coin =
            if ast.gas_coin.is_none() && env.protocol_config.gasless_transaction_drop_safety() {
                None
            } else {
                Some(Value::NonRef)
            };
        let objects = ast.objects.iter().map(|_| Some(Value::NonRef)).collect();
        let withdrawals = ast
            .withdrawals
            .iter()
            .map(|_| Some(Value::NonRef))
            .collect::<Vec<_>>();
        let pure = ast
            .pure
            .iter()
            .map(|_| Some(Value::NonRef))
            .collect::<Vec<_>>();
        let receiving = ast
            .receiving
            .iter()
            .map(|_| Some(Value::NonRef))
            .collect::<Vec<_>>();
        let canonical_reference_capacity = ast
            .commands
            .iter()
            .flat_map(|command| &command.value.result_type)
            .filter(|ty| matches!(&ty, Type::Reference(_, _)))
            .count();
        let (mut graph, _locals) =
            Graph::new::<()>(canonical_reference_capacity, []).map_err(graph_err)?;
        let local_root = graph
            .extend_by_epsilon(
                (),
                std::iter::empty(),
                 true,
                &mut DummyMeter,
            )
            .map_err(graph_meter_err)?;
        Ok(Self {
            graph,
            local_root,
            tx_context: Some(Value::NonRef),
            gas_coin,
            objects,
            withdrawals,
            pure,
            receiving,
            results: Vec::with_capacity(ast.commands.len()),
        })
    }
    fn location(&mut self, l: T::Location) -> Result<&mut Option<Value>, ExecutionError> {
        Ok(match l {
            T::Location::TxContext => &mut self.tx_context,
            T::Location::GasCoin => &mut self.gas_coin,
            T::Location::ObjectInput(i) => self.objects.safe_get_mut(i as usize)?,
            T::Location::WithdrawalInput(i) => self.withdrawals.safe_get_mut(i as usize)?,
            T::Location::PureInput(i) => self.pure.safe_get_mut(i as usize)?,
            T::Location::ReceivingInput(i) => self.receiving.safe_get_mut(i as usize)?,
            T::Location::Result(i, j) => self
                .results
                .safe_get_mut(i as usize)?
                .safe_get_mut(j as usize)?,
        })
    }
    fn is_mutable(&self, r: Ref) -> Result<bool, ExecutionError> {
        self.graph.is_mutable(r).map_err(graph_err)
    }
    fn borrowed_by(&self, r: Ref) -> Result<BTreeMap<Ref, Paths>, ExecutionError> {
        self.graph
            .borrowed_by(r, &mut DummyMeter)
            .map_err(graph_meter_err)
    }
    fn is_location_borrowed(&self, l: T::Location) -> Result<bool, ExecutionError> {
        let borrowed_by = self.borrowed_by(self.local_root)?;
        Ok(borrowed_by
            .iter()
            .any(|(_, paths)| paths.iter().any(|path| path.starts_with(&Location(l)))))
    }
    fn release(&mut self, r: Ref) -> Result<(), ExecutionError> {
        self.graph
            .release(r, &mut DummyMeter)
            .map_err(graph_meter_err)
    }
    fn extend_by_epsilon(&mut self, r: Ref, is_mut: bool) -> Result<Ref, ExecutionError> {
        let new_r = self
            .graph
            .extend_by_epsilon((), std::iter::once(r), is_mut, &mut DummyMeter)
            .map_err(graph_meter_err)?;
        Ok(new_r)
    }
    fn extend_by_label(
        &mut self,
        r: Ref,
        is_mut: bool,
        extension: T::Location,
    ) -> Result<Ref, ExecutionError> {
        let new_r = self
            .graph
            .extend_by_label(
                (),
                std::iter::once(r),
                is_mut,
                Location(extension),
                &mut DummyMeter,
            )
            .map_err(graph_meter_err)?;
        Ok(new_r)
    }
    fn extend_by_dot_star_for_call(
        &mut self,
        sources: &BTreeSet<Ref>,
        mutabilities: Vec<bool>,
    ) -> Result<Vec<Ref>, ExecutionError> {
        let new_refs = self
            .graph
            .extend_by_dot_star_for_call((), sources, mutabilities, &mut DummyMeter)
            .map_err(graph_meter_err)?;
        Ok(new_refs)
    }
    fn is_writable(&self, r: Ref) -> Result<bool, ExecutionError> {
        debug_assert!(self.is_mutable(r)?);
        Ok(self
            .borrowed_by(r)?
            .values()
            .all(|paths| paths.iter().all(|path| path.is_epsilon())))
    }
    fn find_non_transferrable(&self, refs: &BTreeSet<Ref>) -> Result<Option<Ref>, ExecutionError> {
        let borrows = refs
            .iter()
            .copied()
            .map(|r| Ok((r, self.borrowed_by(r)?)))
            .collect::<Result<BTreeMap<_, _>, ExecutionError>>()?;
        let mut_refs = refs
            .iter()
            .copied()
            .filter_map(|r| match self.is_mutable(r) {
                Ok(true) => Some(Ok(r)),
                Ok(false) => None,
                Err(e) => Some(Err(e)),
            })
            .collect::<Result<BTreeSet<_>, ExecutionError>>()?;
        for (r, borrowed_by) in borrows {
            let is_mut = mut_refs.contains(&r);
            for (borrower, paths) in borrowed_by {
                if !is_mut {
                    if mut_refs.contains(&borrower) {
                        return Ok(Some(borrower));
                    }
                } else {
                    for path in paths {
                        if !path.is_epsilon() || refs.contains(&borrower) {
                            return Ok(Some(r));
                        }
                    }
                }
            }
        }
        Ok(None)
    }
}
pub fn verify(env: &Env, ast: &T::Transaction) -> Result<(), ExecutionError> {
    let mut context = Context::new(env, ast)?;
    let commands = &ast.commands;
    for c in commands {
        let result = command(&mut context, c).map_err(|e| e.with_command_index(c.idx as usize))?;
        assert_invariant!(
            result.len() == c.value.result_type.len(),
            "result length mismatch for command. {c:?}"
        );
        assert_invariant!(
            result.len() == c.value.drop_values.len(),
            "drop values length mismatch for command. {c:?}"
        );
        let result_values = result
            .into_iter()
            .zip(c.value.drop_values.iter().copied())
            .map(|(v, drop)| {
                Ok(if !drop {
                    Some(v)
                } else {
                    consume_value(&mut context, v)?;
                    None
                })
            })
            .collect::<Result<Vec<_>, ExecutionError>>()?;
        context.results.push(result_values);
    }
    let Context {
        gas_coin,
        objects,
        pure,
        receiving,
        results,
        ..
    } = &mut context;
    let gas_coin = gas_coin.take();
    let objects = std::mem::take(objects);
    let pure = std::mem::take(pure);
    let receiving = std::mem::take(receiving);
    let results = std::mem::take(results);
    consume_value_opt(&mut context, gas_coin)?;
    for vopt in objects.into_iter().chain(pure).chain(receiving) {
        consume_value_opt(&mut context, vopt)?;
    }
    for result in results {
        for vopt in result {
            consume_value_opt(&mut context, vopt)?;
        }
    }
    assert_invariant!(
        context.borrowed_by(context.local_root)?.is_empty(),
        "reference to local root not released"
    );
    context.release(context.local_root)?;
    assert_invariant!(context.graph.is_empty(), "reference not released");
    assert_invariant!(
        context.tx_context.is_some(),
        "tx_context should never be moved"
    );
    Ok(())
}
fn command(context: &mut Context, sp!(_, c): &T::Command) -> Result<Vec<Value>, ExecutionError> {
    let result_tys = &c.result_type;
    Ok(match &c.command {
        T::Command__::MoveCall(mc) => {
            let T::MoveCall {
                function,
                arguments: args,
            } = &**mc;
            let arg_values = arguments(context, args)?;
            call(context, arg_values, &function.signature)?
        }
        T::Command__::TransferObjects(objects, recipient) => {
            let object_values = arguments(context, objects)?;
            let recipient_value = argument(context, recipient)?;
            consume_values(context, object_values)?;
            consume_value(context, recipient_value)?;
            vec![]
        }
        T::Command__::SplitCoins(_, coin, amounts) => {
            let coin_value = argument(context, coin)?;
            let amount_values = arguments(context, amounts)?;
            consume_values(context, amount_values)?;
            write_ref(context, 0, coin_value)?;
            (0..amounts.len()).map(|_| Value::NonRef).collect()
        }
        T::Command__::MergeCoins(_, target, coins) => {
            let target_value = argument(context, target)?;
            let coin_values = arguments(context, coins)?;
            consume_values(context, coin_values)?;
            write_ref(context, 0, target_value)?;
            vec![]
        }
        T::Command__::MakeMoveVec(_, xs) => {
            let vs = arguments(context, xs)?;
            consume_values(context, vs)?;
            vec![Value::NonRef]
        }
        T::Command__::Publish(_, _, _) => result_tys.iter().map(|_| Value::NonRef).collect(),
        T::Command__::Upgrade(_, _, _, x, _) => {
            let v = argument(context, x)?;
            consume_value(context, v)?;
            vec![Value::NonRef]
        }
    })
}
/ false)?;
    consume_value(context, value)?;
    Ok(Value::Ref(new_r))
}
fn read_ref(context: &mut Context, arg_idx: u16, u: &T::Usage) -> Result<Value, ExecutionError> {
    let value = match u {
        T::Usage::Move(l) => move_value(context, arg_idx, *l)?,
        T::Usage::Copy { location, borrowed } => copy_value(context, arg_idx, *location, borrowed)?,
    };
    assert_invariant!(
        value.is_ref(),
        "type checking should guarantee ReadRef is used on only references"
    );
    consume_value(context, value)?;
    Ok(Value::NonRef)
}
fn write_ref(context: &mut Context, arg_idx: usize, value: Value) -> Result<(), ExecutionError> {
    let Value::Ref(r) = value else {
        invariant_violation!("type checking should guarantee WriteRef is used on only references");
    };
    if !context.is_writable(r)? {
        return Err(command_argument_error(
            CommandArgumentError::CannotWriteToExtendedReference,
            arg_idx,
        ));
    }
    consume_value(context, value)?;
    Ok(())
}
fn call(
    context: &mut Context,
    arg_values: Vec<Value>,
    signature: &T::LoadedFunctionInstantiation,
) -> Result<Vec<Value>, ExecutionError> {
    let sources = arg_values
        .iter()
        .filter_map(|v| v.to_ref())
        .collect::<BTreeSet<_>>();
    if let Some(v) = context.find_non_transferrable(&sources)? {
        let mut_idx = arg_values
            .iter()
            .zip(&signature.parameters)
            .enumerate()
            .find(|(_, (x, ty))| x.to_ref() == Some(v) && matches!(ty, Type::Reference(true, _)));
        let Some((idx, _)) = mut_idx else {
            invariant_violation!("non transferrable value was not found in arguments");
        };
        return Err(command_argument_error(
            CommandArgumentError::InvalidReferenceArgument,
            idx,
        ));
    }
    let mutabilities = signature
        .return_
        .iter()
        .filter_map(|ty| match ty {
            Type::Reference(is_mut, _) => Some(*is_mut),
            _ => None,
        })
        .collect::<Vec<_>>();
    let mutabilities_len = mutabilities.len();
    let mut return_references = context.extend_by_dot_star_for_call(&sources, mutabilities)?;
    assert_invariant!(
        return_references.len() == mutabilities_len,
        "return_references should have the same length as mutabilities"
    );
    let mut return_values: Vec<_> = signature
        .return_
        .iter()
        .rev()
        .map(|ty| {
            Ok(match ty {
                Type::Reference(_is_mut, _) => {
                    let Some(new_ref) = return_references.pop() else {
                        invariant_violation!("return_references has less references than return_");
                    };
                    debug_assert_eq!(context.is_mutable(new_ref)?, *_is_mut);
                    Value::Ref(new_ref)
                }
                _ => Value::NonRef,
            })
        })
        .collect::<Result<Vec<_>, ExecutionError>>()?;
    return_values.reverse();
    assert_invariant!(
        return_references.is_empty(),
        "return_references has more references than return_"
    );
    consume_values(context, arg_values)?;
    Ok(return_values)
}
fn graph_meter_err(e: MeterError<()>) -> ExecutionError {
    match e {
        MeterError::Meter(()) => {
            make_invariant_violation!("DummyMeter should never produce a Meter error")
        }
        MeterError::InvariantViolation(iv) => graph_err(iv),
    }
}
fn graph_err(e: move_regex_borrow_graph::InvariantViolation) -> ExecutionError {
    make_invariant_violation!("Borrow graph invariant violation: {}", e.0)
}
impl fmt::Display for Location {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self.0 {
            T::Location::TxContext => write!(f, "TxContext"),
            T::Location::GasCoin => write!(f, "GasCoin"),
            T::Location::ObjectInput(idx) => write!(f, "ObjectInput({idx})"),
            T::Location::WithdrawalInput(idx) => write!(f, "WithdrawalInput({idx})"),
            T::Location::PureInput(idx) => write!(f, "PureInput({idx})"),
            T::Location::ReceivingInput(idx) => write!(f, "ReceivingInput({idx})"),
            T::Location::Result(i, j) => write!(f, "Result({i}, {j})"),
        }
    }
}