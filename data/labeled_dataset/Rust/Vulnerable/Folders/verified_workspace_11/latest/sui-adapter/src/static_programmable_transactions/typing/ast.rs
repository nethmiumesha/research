use crate::static_programmable_transactions::{
    linkage::resolved_linkage::ResolvedLinkage, loading::ast as L, spanned::Spanned,
};
use indexmap::{IndexMap, IndexSet};
use move_core_types::{account_address::AccountAddress, u256::U256};
use move_vm_types::values::VectorSpecialization;
use std::cell::OnceCell;
use sui_types::base_types::{ObjectID, ObjectRef};
/ bool>,
    pub consumed_shared_objects: Vec<ObjectID>,
}
#[derive(Debug)]
pub enum Command__ {
    MoveCall(Box<MoveCall>),
    TransferObjects(Vec<Argument>, Argument),
    SplitCoins( Type, Argument, Vec<Argument>),
    MergeCoins( Type, Argument, Vec<Argument>),
    MakeMoveVec( Type, Vec<Argument>),
    Publish(Vec<Vec<u8>>, Vec<ObjectID>, ResolvedLinkage),
    Upgrade(
        Vec<Vec<u8>>,
        Vec<ObjectID>,
        ObjectID,
        Argument,
        ResolvedLinkage,
    ),
}
pub type LoadedFunctionInstantiation = L::LoadedFunctionInstantiation;
pub type LoadedFunction = L::LoadedFunction;
#[derive(Debug)]
pub struct MoveCall {
    pub function: LoadedFunction,
    pub arguments: Vec<Argument>,
}
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Debug, Hash)]
pub enum Location {
    TxContext,
    GasCoin,
    ObjectInput(u16),
    WithdrawalInput(u16),
    PureInput(u16),
    ReceivingInput(u16),
    Result(u16, u16),
}
#[derive(Clone, Debug)]
pub enum Usage {
    Move(Location),
    Copy {
        location: Location,
        borrowed: OnceCell<bool>,
    },
}
pub type Argument = Spanned<Argument_>;
pub type Argument_ = (Argument__, Type);
#[derive(Clone, Debug)]
pub enum Argument__ {
    Use(Usage),
    Borrow( bool, Location),
    Read(Usage),
    Freeze(Usage),
}
impl Transaction {
    pub fn types(&self) -> impl Iterator<Item = &Type> {
        let pure_types = self.pure.iter().map(|p| &p.ty);
        let object_types = self.objects.iter().map(|o| &o.ty);
        let receiving_types = self.receiving.iter().map(|r| &r.ty);
        let command_types = self.commands.iter().flat_map(command_types);
        pure_types
            .chain(object_types)
            .chain(receiving_types)
            .chain(command_types)
    }
}
impl Usage {
    pub fn new_move(location: Location) -> Usage {
        Usage::Move(location)
    }
    pub fn new_copy(location: Location) -> Usage {
        Usage::Copy {
            location,
            borrowed: OnceCell::new(),
        }
    }
    pub fn location(&self) -> Location {
        match self {
            Usage::Move(location) => *location,
            Usage::Copy { location, .. } => *location,
        }
    }
}
impl Argument__ {
    pub fn new_move(location: Location) -> Self {
        Self::Use(Usage::new_move(location))
    }
    pub fn new_copy(location: Location) -> Self {
        Self::Use(Usage::new_copy(location))
    }
    pub fn location(&self) -> Location {
        match self {
            Self::Use(usage) | Self::Read(usage) => usage.location(),
            Self::Borrow(_, location) => *location,
            Self::Freeze(usage) => usage.location(),
        }
    }
}
impl Command__ {
    pub fn arguments(&self) -> Box<dyn Iterator<Item = &Argument> + '_> {
        match self {
            Command__::MoveCall(mc) => Box::new(mc.arguments.iter()),
            Command__::TransferObjects(objs, addr) => {
                Box::new(objs.iter().chain(std::iter::once(addr)))
            }
            Command__::SplitCoins(_, coin, amounts) => {
                Box::new(std::iter::once(coin).chain(amounts))
            }
            Command__::MergeCoins(_, target, sources) => {
                Box::new(std::iter::once(target).chain(sources))
            }
            Command__::MakeMoveVec(_, elems) => Box::new(elems.iter()),
            Command__::Publish(_, _, _) => Box::new(std::iter::empty()),
            Command__::Upgrade(_, _, _, arg, _) => Box::new(std::iter::once(arg)),
        }
    }
    pub fn types(&self) -> Box<dyn Iterator<Item = &Type> + '_> {
        match self {
            Command__::TransferObjects(args, arg) => {
                Box::new(std::iter::once(arg).chain(args.iter()).map(argument_type))
            }
            Command__::SplitCoins(ty, arg, args) | Command__::MergeCoins(ty, arg, args) => {
                Box::new(
                    std::iter::once(arg)
                        .chain(args.iter())
                        .map(argument_type)
                        .chain(std::iter::once(ty)),
                )
            }
            Command__::MakeMoveVec(ty, args) => {
                Box::new(args.iter().map(argument_type).chain(std::iter::once(ty)))
            }
            Command__::MoveCall(call) => Box::new(
                call.arguments
                    .iter()
                    .map(argument_type)
                    .chain(call.function.type_arguments.iter())
                    .chain(call.function.signature.parameters.iter())
                    .chain(call.function.signature.return_.iter()),
            ),
            Command__::Upgrade(_, _, _, arg, _) => {
                Box::new(std::iter::once(arg).map(argument_type))
            }
            Command__::Publish(_, _, _) => Box::new(std::iter::empty()),
        }
    }
    pub fn arguments_len(&self) -> usize {
        let n = match self {
            Command__::MoveCall(mc) => mc.arguments.len(),
            Command__::TransferObjects(objs, _) => objs.len().saturating_add(1),
            Command__::SplitCoins(_, _, amounts) => amounts.len().saturating_add(1),
            Command__::MergeCoins(_, _, sources) => sources.len().saturating_add(1),
            Command__::MakeMoveVec(_, elems) => elems.len(),
            Command__::Publish(_, _, _) => 0,
            Command__::Upgrade(_, _, _, _, _) => 1,
        };
        debug_assert_eq!(self.arguments().count(), n);
        n
    }
}
pub fn command_types(cmd: &Command) -> impl Iterator<Item = &Type> {
    let result_types = cmd.value.result_type.iter();
    let command_types = cmd.value.command.types();
    result_types.chain(command_types)
}
pub fn argument_type(arg: &Argument) -> &Type {
    &arg.value.1
}
impl TryFrom<Type> for VectorSpecialization {
    type Error = &'static str;
    fn try_from(value: Type) -> Result<Self, Self::Error> {
        Ok(match value {
            Type::U8 => VectorSpecialization::U8,
            Type::U16 => VectorSpecialization::U16,
            Type::U32 => VectorSpecialization::U32,
            Type::U64 => VectorSpecialization::U64,
            Type::U128 => VectorSpecialization::U128,
            Type::U256 => VectorSpecialization::U256,
            Type::Address => VectorSpecialization::Address,
            Type::Bool => VectorSpecialization::Bool,
            Type::Signer | Type::Vector(_) | Type::Datatype(_) => VectorSpecialization::Container,
            Type::Reference(_, _) => return Err("unexpected reference in vector specialization"),
        })
    }
}