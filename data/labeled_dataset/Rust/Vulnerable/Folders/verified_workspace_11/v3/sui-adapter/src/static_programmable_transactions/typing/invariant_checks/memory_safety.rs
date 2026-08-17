use crate::{
    sp,
    static_programmable_transactions::{env::Env, typing::ast as T},
};
use indexmap::IndexSet;
use std::rc::Rc;
use sui_types::error::ExecutionError;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct Delta {
    command: u16,
    result: u16,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum RootLocation {
    Unknown {
        command: u16,
    },
    Known(T::Location),
}
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct Path {
    root: RootLocation,
    extensions: Vec<Delta>,
}
#[derive(Debug)]
struct PathSet(IndexSet<Path>);
#[derive(Debug)]
enum Value {
    NonRef,
    Ref { is_mut: bool, paths: Rc<PathSet> },
}
#[derive(Debug)]
struct Location {
    self_path: Rc<PathSet>,
    value: Option<Value>,
}
#[derive(Debug)]
struct Context {
    tx_context: Location,
    gas: Location,
    object_inputs: Vec<Location>,
    withdrawal_inputs: Vec<Location>,
    pure_inputs: Vec<Location>,
    receiving_inputs: Vec<Location>,
    results: Vec<Vec<Location>>,
    arg_roots: IndexSet<T::Location>,
}
enum PathComparison {
    Prefix,
    Aliases,
    Extends,
    Disjoint,
}
impl Path {
    fn initial(location: T::Location) -> Self {
        Self {
            root: RootLocation::Known(location),
            extensions: vec![],
        }
    }
    fn compare(&self, other: &Self) -> PathComparison {
        if self.root != other.root {
            return PathComparison::Disjoint;
        };
        let mut self_extensions = self.extensions.iter();
        let mut other_extensions = other.extensions.iter();
        loop {
            match (self_extensions.next(), other_extensions.next()) {
                (Some(self_ext), Some(other_ext)) => {
                    if self_ext.command != other_ext.command {
                        return PathComparison::Extends;
                    }
                    if self_ext.result != other_ext.result {
                        return PathComparison::Disjoint;
                    }
                }
                (None, Some(_)) => return PathComparison::Prefix,
                (Some(_), None) => return PathComparison::Extends,
                (None, None) => return PathComparison::Aliases,
            }
        }
    }
    fn extend(&self, extension: Delta) -> Self {
        let mut new_extensions = self.extensions.clone();
        new_extensions.push(extension);
        Self {
            root: self.root,
            extensions: new_extensions,
        }
    }
}
impl PathSet {
    fn empty() -> Self {
        Self(IndexSet::new())
    }
    fn initial(location: T::Location) -> Self {
        Self(IndexSet::from([Path::initial(location)]))
    }
    fn unknown_root(command: u16) -> Self {
        Self(IndexSet::from([Path {
            root: RootLocation::Unknown { command },
            extensions: vec![],
        }]))
    }
    fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
    fn extends(&self, other: &Self, ignore_aliases: bool) -> bool {
        self.0.iter().any(|self_path| {
            other
                .0
                .iter()
                .any(|other_path| match self_path.compare(other_path) {
                    PathComparison::Prefix | PathComparison::Disjoint => false,
                    PathComparison::Aliases => !ignore_aliases,
                    PathComparison::Extends => true,
                })
        })
    }
    fn is_disjoint(&self, other: &Self) -> bool {
        self.0.iter().all(|self_path| {
            other
                .0
                .iter()
                .all(|other_path| match self_path.compare(other_path) {
                    PathComparison::Disjoint => true,
                    PathComparison::Prefix | PathComparison::Aliases | PathComparison::Extends => {
                        false
                    }
                })
        })
    }
    fn union(&mut self, other: &PathSet) {
        self.0.extend(other.0.iter().cloned());
    }
    fn extend(&self, extension: Delta) -> Self {
        let mut new_paths = IndexSet::with_capacity(self.0.len());
        for path in &self.0 {
            new_paths.insert(path.extend(extension));
        }
        Self(new_paths)
    }
}
impl Value {
    fn ref_(is_mut: bool, paths: PathSet) -> anyhow::Result<Value> {
        anyhow::ensure!(
            !paths.is_empty(),
            "Cannot create a reference with an empty path set"
        );
        Ok(Value::Ref {
            is_mut,
            paths: Rc::new(paths),
        })
    }
    fn copy(&self) -> Value {
        match self {
            Value::NonRef => Value::NonRef,
            Value::Ref { is_mut, paths } => Value::Ref {
                is_mut: *is_mut,
                paths: paths.clone(),
            },
        }
    }
    fn freeze(&mut self) -> anyhow::Result<Value> {
        let copied = self.copy();
        match copied {
            Value::NonRef => {
                anyhow::bail!("Cannot freeze a non-reference value")
            }
            Value::Ref { is_mut, paths } => {
                anyhow::ensure!(is_mut, "Cannot freeze an immutable reference");
                Ok(Value::Ref {
                    is_mut: false,
                    paths,
                })
            }
        }
    }
}
impl Location {
    fn non_ref(location: T::Location) -> Self {
        Self {
            self_path: Rc::new(PathSet::initial(location)),
            value: Some(Value::NonRef),
        }
    }
    fn copy_value(&self) -> anyhow::Result<Value> {
        let Some(value) = self.value.as_ref() else {
            anyhow::bail!("Use of invalid memory location")
        };
        Ok(value.copy())
    }
    fn move_value(&mut self) -> anyhow::Result<Value> {
        let Some(value) = self.value.take() else {
            anyhow::bail!("Use of invalid memory location")
        };
        Ok(value)
    }
    fn use_(&mut self, usage: &T::Usage) -> anyhow::Result<Value> {
        match usage {
            T::Usage::Move(_) => self.move_value(),
            T::Usage::Copy { .. } => self.copy_value(),
        }
    }
    fn borrow(&mut self, is_mut: bool) -> anyhow::Result<Value> {
        let Some(value) = self.value.as_ref() else {
            anyhow::bail!("Borrow of invalid memory location")
        };
        match value {
            Value::Ref { .. } => {
                anyhow::bail!("Cannot borrow a reference")
            }
            Value::NonRef => {
                anyhow::ensure!(
                    !self.self_path.is_empty(),
                    "Cannot have an empty location to borrow from"
                );
                Ok(Value::Ref {
                    is_mut,
                    paths: self.self_path.clone(),
                })
            }
        }
    }
}
impl Context {
    fn new(env: &Env, txn: &T::Transaction) -> anyhow::Result<Self> {
        let T::Transaction {
            gas_coin,
            bytes: _,
            objects,
            withdrawals,
            pure,
            receiving,
            withdrawal_compatibility_conversions: _,
            commands: _,
        } = txn;
        let tx_context = Location::non_ref(T::Location::TxContext);
        let mut gas = Location::non_ref(T::Location::GasCoin);
        if gas_coin.is_none() && env.protocol_config.gasless_transaction_drop_safety() {
            gas.move_value()
                .map_err(|_| anyhow::anyhow!("gas coin should be initialized"))?;
        }
        let object_inputs = (0..objects.len())
            .map(|i| {
                Ok(Location::non_ref(T::Location::ObjectInput(checked_as!(
                    i, u16
                )?)))
            })
            .collect::<Result<_, ExecutionError>>()?;
        let withdrawal_inputs = (0..withdrawals.len())
            .map(|i| {
                Ok(Location::non_ref(T::Location::WithdrawalInput(
                    checked_as!(i, u16)?,
                )))
            })
            .collect::<Result<_, ExecutionError>>()?;
        let pure_inputs = (0..pure.len())
            .map(|i| {
                Ok(Location::non_ref(T::Location::PureInput(checked_as!(
                    i, u16
                )?)))
            })
            .collect::<Result<_, ExecutionError>>()?;
        let receiving_inputs = (0..receiving.len())
            .map(|i| {
                Ok(Location::non_ref(T::Location::ReceivingInput(checked_as!(
                    i, u16
                )?)))
            })
            .collect::<Result<_, ExecutionError>>()?;
        Ok(Self {
            tx_context,
            gas,
            object_inputs,
            withdrawal_inputs,
            pure_inputs,
            receiving_inputs,
            results: vec![],
            arg_roots: IndexSet::new(),
        })
    }
    fn current_command(&self) -> anyhow::Result<u16> {
        Ok(checked_as!(self.results.len(), u16)?)
    }
    fn add_result_values(
        &mut self,
        results: impl IntoIterator<Item = Option<Value>>,
    ) -> anyhow::Result<()> {
        let command = self.current_command()?;
        self.results.push(
            results
                .into_iter()
                .enumerate()
                .map(|(i, v)| {
                    Ok(Location {
                        self_path: Rc::new(PathSet::initial(T::Location::Result(
                            command,
                            checked_as!(i, u16)?,
                        ))),
                        value: v,
                    })
                })
                .collect::<Result<_, ExecutionError>>()?,
        );
        Ok(())
    }
    fn location(&self, loc: T::Location) -> anyhow::Result<&Location> {
        Ok(match loc {
            T::Location::TxContext => &self.tx_context,
            T::Location::GasCoin => &self.gas,
            T::Location::ObjectInput(i) => self
                .object_inputs
                .get(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Object input index out of bounds {i}"))?,
            T::Location::WithdrawalInput(i) => self
                .withdrawal_inputs
                .get(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Withdrawal input index out of bounds {i}"))?,
            T::Location::PureInput(i) => self
                .pure_inputs
                .get(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Pure input index out of bounds {i}"))?,
            T::Location::ReceivingInput(i) => self
                .receiving_inputs
                .get(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Receiving input index out of bounds {i}"))?,
            T::Location::Result(i, j) => self
                .results
                .get(i as usize)
                .and_then(|r| r.get(j as usize))
                .ok_or_else(|| anyhow::anyhow!("Result index out of bounds ({i},{j})"))?,
        })
    }
    fn location_mut(&mut self, loc: T::Location) -> anyhow::Result<&mut Location> {
        Ok(match loc {
            T::Location::TxContext => &mut self.tx_context,
            T::Location::GasCoin => &mut self.gas,
            T::Location::ObjectInput(i) => self
                .object_inputs
                .get_mut(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Object input index out of bounds {i}"))?,
            T::Location::WithdrawalInput(i) => self
                .withdrawal_inputs
                .get_mut(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Withdrawal input index out of bounds {i}"))?,
            T::Location::PureInput(i) => self
                .pure_inputs
                .get_mut(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Pure input index out of bounds {i}"))?,
            T::Location::ReceivingInput(i) => self
                .receiving_inputs
                .get_mut(i as usize)
                .ok_or_else(|| anyhow::anyhow!("Receiving input index out of bounds {i}"))?,
            T::Location::Result(i, j) => self
                .results
                .get_mut(i as usize)
                .and_then(|r| r.get_mut(j as usize))
                .ok_or_else(|| anyhow::anyhow!("Result index out of bounds ({i},{j})"))?,
        })
    }
    fn check_usage(&self, usage: &T::Usage, location: &Location) -> anyhow::Result<()> {
        let is_borrowed = self.any_extends(&location.self_path,  false)
            || self.arg_roots.contains(&usage.location());
        match usage {
            T::Usage::Move(_) => {
                anyhow::ensure!(!is_borrowed, "Cannot move a value that is borrowed");
            }
            T::Usage::Copy { borrowed, .. } => {
                let Some(borrowed) = borrowed.get().copied() else {
                    anyhow::bail!("Borrowed flag not set for copy usage");
                };
                anyhow::ensure!(
                    borrowed == is_borrowed,
                    "Borrowed flag mismatch for copy usage: expected {borrowed}, got {is_borrowed} \
                    location {:?} for in command {}",
                    location.self_path,
                    self.current_command()?
                );
            }
        }
        Ok(())
    }
    fn argument(&mut self, sp!(_, (arg, _)): &T::Argument) -> anyhow::Result<Value> {
        let location = self.location(arg.location())?;
        match arg {
            T::Argument__::Use(usage)
            | T::Argument__::Freeze(usage)
            | T::Argument__::Read(usage) => self.check_usage(usage, location)?,
            T::Argument__::Borrow(_, _) => (),
        };
        let location = self.location_mut(arg.location())?;
        let value = match arg {
            T::Argument__::Use(usage) => location.use_(usage)?,
            T::Argument__::Freeze(usage) => location.use_(usage)?.freeze()?,
            T::Argument__::Borrow(is_mut, _) => location.borrow(*is_mut)?,
            T::Argument__::Read(usage) => {
                location.use_(usage)?;
                Value::NonRef
            }
        };
        if let Value::Ref { paths, .. } = &value {
            for p in &paths.0 {
                match p.root {
                    RootLocation::Unknown { .. } => (),
                    RootLocation::Known(location) => {
                        self.arg_roots.insert(location);
                    }
                }
            }
        }
        Ok(value)
    }
    fn arguments(&mut self, args: &[T::Argument]) -> anyhow::Result<Vec<Value>> {
        args.iter()
            .map(|arg| self.argument(arg))
            .collect::<anyhow::Result<Vec<_>>>()
    }
    fn all_references(&self) -> impl Iterator<Item = Rc<PathSet>> {
        let Self {
            tx_context,
            gas,
            object_inputs,
            withdrawal_inputs,
            pure_inputs,
            receiving_inputs,
            results,
            arg_roots: _,
        } = self;
        std::iter::once(tx_context)
            .chain(std::iter::once(gas))
            .chain(object_inputs)
            .chain(withdrawal_inputs)
            .chain(pure_inputs)
            .chain(receiving_inputs)
            .chain(results.iter().flatten())
            .filter_map(|v| -> Option<Rc<PathSet>> {
                match v.value.as_ref() {
                    Some(Value::Ref { paths, .. }) => Some(paths.clone()),
                    Some(Value::NonRef) | None => None,
                }
            })
    }
    fn any_extends(&self, paths: &PathSet, ignore_aliases: bool) -> bool {
        self.all_references()
            .any(|other| other.extends(paths, ignore_aliases))
    }
}
pub fn verify(env: &Env, txn: &T::Transaction) -> Result<(), ExecutionError> {
    verify_(env, txn).map_err(|e| make_invariant_violation!("{}. Transaction {:?}", e, txn))
}
fn verify_(env: &Env, txn: &T::Transaction) -> anyhow::Result<()> {
    let mut context = Context::new(env, txn)?;
    let T::Transaction {
        gas_coin: _,
        bytes: _,
        objects: _,
        withdrawals: _,
        pure: _,
        receiving: _,
        withdrawal_compatibility_conversions: _,
        commands,
    } = txn;
    for c in commands {
        command(&mut context, c)?;
    }
    Ok(())
}
fn command(context: &mut Context, c: &T::Command) -> anyhow::Result<()> {
    debug_assert!(context.arg_roots.is_empty());
    let results = command_(context, c)?;
    assert_invariant!(
        results.len() == c.value.drop_values.len(),
        "result length mismatch. expected {}, got {}",
        c.value.drop_values.len(),
        results.len()
    );
    context.add_result_values(
        results
            .into_iter()
            .zip(c.value.drop_values.iter().copied())
            .map(|(v, drop)| if drop { None } else { Some(v) }),
    )?;
    context.arg_roots.clear();
    Ok(())
}
fn command_(context: &mut Context, sp!(_, c): &T::Command) -> anyhow::Result<Vec<Value>> {
    let result_tys = &c.result_type;
    let results = match &c.command {
        T::Command__::MoveCall(move_call) => {
            let T::MoveCall {
                function,
                arguments,
            } = &**move_call;
            let arg_values = context.arguments(arguments)?;
            call(context, &function.signature, arg_values)?
        }
        T::Command__::TransferObjects(objs, recipient) => {
            context.arguments(objs)?;
            context.argument(recipient)?;
            non_ref_results(result_tys)?
        }
        T::Command__::SplitCoins(_, coin, amounts) => {
            context.arguments(amounts)?;
            let coin_value = context.argument(coin)?;
            write_ref(context, coin_value)?;
            non_ref_results(result_tys)?
        }
        T::Command__::MergeCoins(_, target, coins) => {
            context.arguments(coins)?;
            let target_value = context.argument(target)?;
            write_ref(context, target_value)?;
            non_ref_results(result_tys)?
        }
        T::Command__::MakeMoveVec(_, arguments) => {
            context.arguments(arguments)?;
            non_ref_results(result_tys)?
        }
        T::Command__::Publish(_, _, _) => non_ref_results(result_tys)?,
        T::Command__::Upgrade(_, _, _, ticket, _) => {
            context.argument(ticket)?;
            non_ref_results(result_tys)?
        }
    };
    assert_invariant!(
        result_tys.len() == results.len(),
        "result length mismatch. Expected {}, got {}",
        result_tys.len(),
        results.len()
    );
    Ok(results)
}
fn write_ref(context: &Context, value: Value) -> anyhow::Result<()> {
    match value {
        Value::NonRef => {
            anyhow::bail!("Cannot write to a non-reference value");
        }
        Value::Ref { is_mut: false, .. } => {
            anyhow::bail!("Cannot write to an immutable reference");
        }
        Value::Ref {
            is_mut: true,
            paths,
        } => {
            anyhow::ensure!(
                !context.any_extends(&paths,  true),
                "Cannot write to a mutable reference that has extensions"
            );
            Ok(())
        }
    }
}
fn call(
    context: &mut Context,
    signature: &T::LoadedFunctionInstantiation,
    arguments: Vec<Value>,
) -> anyhow::Result<Vec<Value>> {
    let return_ = &signature.return_;
    let mut all_paths: PathSet = PathSet::empty();
    let mut imm_paths: PathSet = PathSet::empty();
    let mut mut_paths: PathSet = PathSet::empty();
    for arg in arguments {
        match arg {
            Value::NonRef => (),
            Value::Ref {
                is_mut: true,
                paths,
            } => {
                anyhow::ensure!(
                    !context.any_extends(&paths,  true),
                    "Cannot transfer a mutable ref with extensions"
                );
                anyhow::ensure!(mut_paths.is_disjoint(&paths), "Double mutable borrow");
                all_paths.union(&paths);
                mut_paths.union(&paths);
            }
            Value::Ref {
                is_mut: false,
                paths,
            } => {
                all_paths.union(&paths);
                imm_paths.union(&paths);
            }
        }
    }
    anyhow::ensure!(
        imm_paths.is_disjoint(&mut_paths),
        "Mutable and immutable borrows cannot overlap"
    );
    let command = context.current_command()?;
    let mut_paths = if mut_paths.is_empty() {
        PathSet::unknown_root(command)
    } else {
        mut_paths
    };
    let all_paths = if all_paths.is_empty() {
        PathSet::unknown_root(command)
    } else {
        all_paths
    };
    return_
        .iter()
        .enumerate()
        .map(|(i, ty)| {
            let delta = Delta {
                command,
                result: checked_as!(i, u16)?,
            };
            match ty {
                T::Type::Reference( true, _) => {
                    Value::ref_(true, mut_paths.extend(delta))
                }
                T::Type::Reference( false, _) => {
                    Value::ref_(false, all_paths.extend(delta))
                }
                _ => Ok(Value::NonRef),
            }
        })
        .collect::<anyhow::Result<Vec<_>>>()
}
fn non_ref_results(results: &[T::Type]) -> anyhow::Result<Vec<Value>> {
    results
        .iter()
        .map(|t| {
            anyhow::ensure!(
                !matches!(t, T::Type::Reference(_, _)),
                "attempted to create a non-reference result from a reference type",
            );
            Ok(Value::NonRef)
        })
        .collect()
}
impl Path {
    #[cfg(debug_assertions)]
    #[allow(unused)]
    fn print(&self) {
        print!("{:?}", self.root);
        for ext in &self.extensions {
            let Delta { command, result } = ext;
            print!(".d{}_{}", command, result);
        }
        println!(",");
    }
}
impl PathSet {
    #[cfg(debug_assertions)]
    #[allow(unused)]
    fn print(&self) {
        println!("{{");
        for path in &self.0 {
            path.print();
        }
        println!("}}");
    }
}
impl Value {
    #[cfg(debug_assertions)]
    #[allow(unused)]
    fn print(&self) {
        match self {
            Value::NonRef => print!("NonRef"),
            Value::Ref { is_mut, paths } => {
                if *is_mut {
                    print!("mut ");
                } else {
                    print!("imm ");
                }
                paths.print();
            }
        }
    }
}
impl Location {
    #[cfg(debug_assertions)]
    #[allow(unused)]
    fn print(&self) {
        print!("{{ self_path: ");
        self.self_path.print();
        print!(", value: ");
        if let Some(value) = &self.value {
            value.print();
        } else {
            println!("_");
        }
        println!("}}");
    }
}
impl Context {
    #[cfg(debug_assertions)]
    #[allow(unused)]
    fn print(&self) {
        println!("Context {{");
        println!("  tx_context: ");
        self.tx_context.print();
        println!("  gas: ");
        self.gas.print();
        println!("  object_inputs: [");
        for input in &self.object_inputs {
            input.print();
        }
        println!("  ],");
        println!("  pure_inputs: [");
        for input in &self.pure_inputs {
            input.print();
        }
        println!("  ],");
        println!("  receiving_inputs: [");
        for input in &self.receiving_inputs {
            input.print();
        }
        println!("  ],");
        println!("  results: [");
        for result in &self.results {
            for loc in result {
                loc.print();
            }
            println!(",");
        }
        println!("  ],");
        println!("}}");
    }
}