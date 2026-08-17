use std::collections::BTreeSet;
use crate::execution_mode::ExecutionMode;
use crate::sp;
use crate::static_programmable_transactions::{env::Env, typing::ast as T};
use move_binary_format::{CompiledModule, file_format::Visibility};
use sui_types::error::SafeIndex;
use sui_types::{
    error::{ExecutionError, command_argument_error},
    execution_status::CommandArgumentError,
};
#[derive(Clone, Copy, Debug)]
enum Temperature {
    AlwaysHot,
    Count(usize),
}
enum Clique {
    Merged(CliqueID),
    Root(Temperature),
}
type CliqueID = usize;
#[must_use]
enum Value {
    TxContext,
    Normal {
        clique: CliqueID,
        heats: bool,
    },
}
struct Cliques(Vec<Clique>);
struct Context {
    cliques: Cliques,
    tx_context: Option<Value>,
    gas_coin: Option<Value>,
    objects: Vec<Option<Value>>,
    withdrawals: Vec<Option<Value>>,
    pure: Vec<Option<Value>>,
    receiving: Vec<Option<Value>>,
    results: Vec<Vec<Option<Value>>>,
}
impl Temperature {
    fn add(self, other: Temperature) -> Result<Temperature, ExecutionError> {
        Ok(match (self, other) {
            (Temperature::AlwaysHot, _) | (_, Temperature::AlwaysHot) => Temperature::AlwaysHot,
            (Temperature::Count(a), Temperature::Count(b)) => Temperature::Count(
                a.checked_add(b)
                    .ok_or_else(|| make_invariant_violation!("Hot count overflow"))?,
            ),
        })
    }
    fn sub(self, b: usize) -> Result<Temperature, ExecutionError> {
        Ok(match self {
            Temperature::AlwaysHot => Temperature::AlwaysHot,
            Temperature::Count(a) => Temperature::Count(
                a.checked_sub(b)
                    .ok_or_else(|| make_invariant_violation!("Hot count cannot go negative"))?,
            ),
        })
    }
    fn is_hot(&self) -> bool {
        match self {
            Temperature::AlwaysHot => true,
            Temperature::Count(c) => *c > 0,
        }
    }
}
impl Cliques {
    fn new() -> Self {
        Self(vec![])
    }
    fn next(&mut self) -> CliqueID {
        let id = self.0.len();
        self.0.push(Clique::Root(Temperature::Count(0)));
        id
    }
    fn root(&self, id: CliqueID) -> Result<CliqueID, ExecutionError> {
        let mut visited = BTreeSet::from([id]);
        let mut cur = id;
        loop {
            match self.0.safe_get(cur)? {
                Clique::Root(_) => return Ok(cur),
                Clique::Merged(next) => {
                    let newly_visited = visited.insert(*next);
                    if !newly_visited {
                        invariant_violation!("Clique merge cycle detected");
                    }
                    cur = *next
                }
            }
        }
    }
    fn temp(&self, id: CliqueID) -> Result<Temperature, ExecutionError> {
        let root = self.root(id)?;
        let Clique::Root(temp) = *self.0.safe_get(root)? else {
            invariant_violation!("Clique {root} should be a root");
        };
        Ok(temp)
    }
    fn temp_mut(&mut self, id: CliqueID) -> Result<&mut Temperature, ExecutionError> {
        let root = self.root(id)?;
        let Clique::Root(temp) = self.0.safe_get_mut(root)? else {
            invariant_violation!("Clique {root} should be a root");
        };
        Ok(temp)
    }
    fn modify_temp(
        &mut self,
        id: CliqueID,
        f: impl FnOnce(Temperature) -> Result<Temperature, ExecutionError>,
    ) -> Result<(), ExecutionError> {
        let temp = self.temp_mut(id)?;
        *temp = f(*temp)?;
        Ok(())
    }
    fn merge(&mut self, clique_ids: BTreeSet<CliqueID>) -> Result<CliqueID, ExecutionError> {
        let roots: BTreeSet<CliqueID> = clique_ids
            .iter()
            .map(|&id| self.root(id))
            .collect::<Result<_, _>>()?;
        Ok(match roots.len() {
            0 => self.next(),
            1 => *roots.iter().next().unwrap(),
            _ => {
                let merged = self.next();
                let mut merged_temp = Temperature::Count(0);
                for &root in &roots {
                    let temp = self.temp(root)?;
                    *self.0.safe_get_mut(root)? = Clique::Merged(merged);
                    merged_temp = merged_temp.add(temp)?;
                }
                *self.0.safe_get_mut(merged)? = Clique::Root(merged_temp);
                for id in clique_ids {
                    *self.0.safe_get_mut(id)? = Clique::Merged(merged);
                }
                merged
            }
        })
    }
    fn input_value(&mut self) -> Value {
        let clique = self.next();
        Value::Normal {
            clique,
            heats: false,
        }
    }
    fn new_value(&mut self, clique: CliqueID, heats: bool) -> Result<Value, ExecutionError> {
        if heats {
            self.modify_temp(clique, |t| t.add(Temperature::Count(1)))?;
        }
        Ok(Value::Normal { clique, heats })
    }
    fn release_value(&mut self, value: Value) -> Result<Option<CliqueID>, ExecutionError> {
        let (clique, heats) = match value {
            Value::TxContext => return Ok(None),
            Value::Normal { clique, heats } => (clique, heats),
        };
        if heats {
            self.modify_temp(clique, |t| t.sub(1))?;
        }
        Ok(Some(clique))
    }
    fn is_hot(&self, clique: CliqueID) -> Result<bool, ExecutionError> {
        Ok(self.temp(clique)?.is_hot())
    }
    fn mark_always_hot(&mut self, clique: CliqueID) -> Result<(), ExecutionError> {
        self.modify_temp(clique, |_| Ok(Temperature::AlwaysHot))
    }
}
impl Context {
    fn new(txn: &T::Transaction) -> Self {
        let mut cliques = Cliques::new();
        let tx_context = Some(Value::TxContext);
        let gas_coin = Some(cliques.input_value());
        let objects = (0..txn.objects.len())
            .map(|_| Some(cliques.input_value()))
            .collect();
        let withdrawals = (0..txn.withdrawals.len())
            .map(|_| Some(cliques.input_value()))
            .collect();
        let pure = (0..txn.pure.len())
            .map(|_| Some(cliques.input_value()))
            .collect();
        let receiving = (0..txn.receiving.len())
            .map(|_| Some(cliques.input_value()))
            .collect();
        Self {
            tx_context,
            cliques,
            gas_coin,
            objects,
            withdrawals,
            pure,
            receiving,
            results: vec![],
        }
    }
    fn finish(self) -> Result<(), ExecutionError> {
        let Context {
            mut cliques,
            tx_context,
            gas_coin,
            objects,
            withdrawals,
            pure,
            receiving,
            results,
        } = self;
        let all_values = tx_context
            .into_iter()
            .chain(gas_coin)
            .chain(objects.into_iter().flatten())
            .chain(withdrawals.into_iter().flatten())
            .chain(pure.into_iter().flatten())
            .chain(receiving.into_iter().flatten())
            .chain(results.into_iter().flatten().flatten());
        let mut clique_ids: BTreeSet<CliqueID> = BTreeSet::new();
        for value in all_values {
            let clique = match &value {
                Value::TxContext => continue,
                Value::Normal { clique, .. } => clique,
            };
            clique_ids.insert(*clique);
            cliques.release_value(value)?;
        }
        for id in clique_ids {
            match cliques.temp(id)? {
                Temperature::AlwaysHot => (),
                Temperature::Count(c) => {
                    assert_invariant!(c == 0, "All hot counts should be zero at end")
                }
            }
        }
        Ok(())
    }
    fn location(&mut self, location: &T::Location) -> Result<&mut Option<Value>, ExecutionError> {
        Ok(match location {
            T::Location::GasCoin => &mut self.gas_coin,
            T::Location::ObjectInput(i) => self.objects.safe_get_mut(*i as usize)?,
            T::Location::WithdrawalInput(i) => self.withdrawals.safe_get_mut(*i as usize)?,
            T::Location::PureInput(i) => self.pure.safe_get_mut(*i as usize)?,
            T::Location::ReceivingInput(i) => self.receiving.safe_get_mut(*i as usize)?,
            T::Location::Result(i, j) => self
                .results
                .safe_get_mut(*i as usize)?
                .safe_get_mut(*j as usize)?,
            T::Location::TxContext => &mut self.tx_context,
        })
    }
    fn usage(&mut self, usage: &T::Usage) -> Result<Value, ExecutionError> {
        match usage {
            T::Usage::Move(location) => {
                let Some(value) = self.location(location)?.take() else {
                    invariant_violation!("Move of moved value");
                };
                Ok(value)
            }
            T::Usage::Copy { location, .. } => {
                let Some(location) = self.location(location)?.as_ref() else {
                    invariant_violation!("Copy of moved value");
                };
                let (clique, heats) = match location {
                    Value::TxContext => {
                        invariant_violation!("Cannot copy TxContext");
                    }
                    Value::Normal { clique, heats } => (*clique, *heats),
                };
                self.cliques.new_value(clique, heats)
            }
        }
    }
    fn argument(&mut self, sp!(_, (arg, _ty)): &T::Argument) -> Result<Value, ExecutionError> {
        Ok(match arg {
            T::Argument__::Use(usage) => self.usage(usage)?,
            T::Argument__::Read(usage) | T::Argument__::Freeze(usage) => {
                let value = self.usage(usage)?;
                let (clique, heats) = match &value {
                    Value::TxContext => {
                        invariant_violation!("Cannot read or freeze TxContext");
                    }
                    Value::Normal { clique, heats } => (*clique, *heats),
                };
                let new_value = self.cliques.new_value(clique, heats)?;
                self.cliques.release_value(value)?;
                new_value
            }
            T::Argument__::Borrow(_, location) => {
                let Some(location) = self.location(location)?.as_ref() else {
                    invariant_violation!("Borrow of moved value");
                };
                let (clique, heats) = match location {
                    Value::TxContext => {
                        return Ok(Value::TxContext);
                    }
                    Value::Normal { clique, heats } => (*clique, *heats),
                };
                self.cliques.new_value(clique, heats)?
            }
        })
    }
}
pub fn verify<Mode: ExecutionMode>(env: &Env, txn: &T::Transaction) -> Result<(), ExecutionError> {
    let mut context = Context::new(txn);
    for c in &txn.commands {
        let result_values = command::<Mode>(env, &mut context, c)
            .map_err(|e| e.with_command_index(c.idx as usize))?;
        assert_invariant!(
            result_values.len() == c.value.result_type.len(),
            "result length mismatch"
        );
        context.results.push(result_values);
    }
    context.finish()?;
    Ok(())
}
fn command<Mode: ExecutionMode>(
    env: &Env,
    context: &mut Context,
    sp!(_, c): &T::Command,
) -> Result<Vec<Option<Value>>, ExecutionError> {
    let T::Command_ {
        command,
        result_type,
        drop_values,
        consumed_shared_objects,
    } = c;
    let argument_cliques = arguments(env, context, command.arguments())?;
    match command {
        T::Command__::MoveCall(call) => move_call::<Mode>(env, context, call, &argument_cliques)?,
        T::Command__::TransferObjects(_, _)
        | T::Command__::SplitCoins(_, _, _)
        | T::Command__::MergeCoins(_, _, _)
        | T::Command__::MakeMoveVec(_, _)
        | T::Command__::Publish(_, _, _)
        | T::Command__::Upgrade(_, _, _, _, _) => (),
    }
    let merged_clique = context
        .cliques
        .merge(argument_cliques.into_iter().map(|(_, c)| c).collect())?;
    let consumes_shared_objects = !consumed_shared_objects.is_empty();
    if consumes_shared_objects {
        context.cliques.mark_always_hot(merged_clique)?;
    }
    assert_invariant!(
        drop_values.len() == result_type.len(),
        "drop_values length mismatch"
    );
    result_type
        .iter()
        .zip(drop_values)
        .map(|(ty, dropped)| {
            Ok(if *dropped {
                None
            } else {
                let heats = is_hot_potato_return_type(ty);
                Some(context.cliques.new_value(merged_clique, heats)?)
            })
        })
        .collect()
}
fn arguments<'a>(
    env: &Env,
    context: &mut Context,
    args: impl IntoIterator<Item = &'a T::Argument>,
) -> Result<Vec<(u16, CliqueID)>, ExecutionError> {
    let mut arguments = vec![];
    for arg in args {
        if let Some(clique) = argument(env, context, arg)? {
            arguments.push((arg.idx, clique));
        }
    }
    Ok(arguments)
}
fn argument(
    _env: &Env,
    context: &mut Context,
    arg: &T::Argument,
) -> Result<Option<CliqueID>, ExecutionError> {
    let value = context.argument(arg)?;
    context.cliques.release_value(value)
}
fn move_call<Mode: ExecutionMode>(
    env: &Env,
    context: &mut Context,
    call: &T::MoveCall,
    argument_cliques: &[(u16, CliqueID)],
) -> Result<(), ExecutionError> {
    let T::MoveCall {
        function,
        arguments: _,
    } = call;
    let module = env.module_definition(&function.runtime_id, &function.linkage)?;
    let module: &CompiledModule = module.as_ref();
    let Some((_index, fdef)) = module.find_function_def_by_name(function.name.as_str()) else {
        invariant_violation!(
            "Could not resolve function '{}' in module {}. \
            This should have been checked when linking",
            &function.name,
            module.self_id(),
        );
    };
    let visibility = fdef.visibility;
    let is_entry = fdef.is_entry;
    let is_non_public = if env.protocol_config.restrict_hot_or_not_entry_functions() {
        !matches!(visibility, Visibility::Public)
    } else {
        matches!(visibility, Visibility::Private)
    };
    if is_entry && is_non_public && !Mode::allow_arbitrary_values() {
        let mut hot_argument: Option<u16> = None;
        for (idx, clique) in argument_cliques {
            if context.cliques.is_hot(*clique)? {
                hot_argument = Some(*idx);
                break;
            }
        }
        if let Some(idx) = hot_argument {
            return Err(command_argument_error(
                CommandArgumentError::InvalidArgumentToPrivateEntryFunction,
                idx as usize,
            ));
        }
    }
    Ok(())
}
fn is_hot_potato_return_type(ty: &T::Type) -> bool {
    let abilities = ty.abilities();
    !abilities.has_drop() && !abilities.has_store()
}