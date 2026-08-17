#![allow(dead_code)]
#![allow(unused_imports)]
extern crate bytes;
extern crate bytes as my_bytes;
extern crate core as my_core;
extern crate std as ruststd;
extern crate lazy_static as _;
use ::core;
use std;
use ::log;
use lazy_static;
use ::native_tls as ntls;
use toml as tjson;
use ::core::primitive::i64;
use std::primitive::u64;
use ::log::logger;
use lazy_static::lazy;
use ::mailparse::MailHeader as AMailHeader;
use env_logger::Logger as BLogger;
use self::foo::foo_fn;
mod middle {
    mod inner {
        use super::super::foo_fn;
    }
}
use {};
use foo::*;
use foo::{};
use ::std::io::{self, Read as _};
use std::{io::BufReader, path::{Path, PathBuf}};
use libc::*;
use ::std::{
    process::{
        ChildStdin,
        ChildStderr,
    },
    fs::remove_dir as empty_dir
};
use std::{
    io::BufWriter,
    path::{
        Component, Components
    }
};
use minimad::{
    TextTemplate, TextTemplateExpander
};
use {
    async_std::fs::File,
    clap::{
        App, AppSettings, Arg
    },
    chrono::{Utc, DateTime, Date},
    tokio::{
        net::{
            TcpStream, TcpSocket
        },
        io::BufWriter as TokioWriter,
        io::ErrorKind::{
            Interrupted, InvalidData,
            InvalidInput, AddrInUse
        },
    }
};
use octolinker_rust_test_cases::Error;
pub use core::hash::BuildHasher;
pub use std::io::ErrorKind;
pub use once_cell;
pub use near_sdk::{
    env, ext_contract, near_bindgen, AccountId,
    Balance, Promise, PromiseResult, PublicKey,
};
pub(self) use core::slice::SplitMut;
pub(self) use std::io::Empty;
pub(self) use terminal_size;
pub(self) use near_sdk::{
   Duration, BlockHeight
};
mod test_pub_super_use {
    pub(super) use core::task::Context;
    pub(super) use std::io::IntoInnerError;
    pub(super) use once_cell;
    pub(super) use near_sdk::{
        env, ext_contract, near_bindgen, AccountId,
        Balance, Promise, PromiseResult, PublicKey,
    };
}
pub(in self) use core::debug_assert_ne;
pub(in self) use std::io::Repeat;
pub(in self) use serde_json;
pub(in self) use near_sdk::{
    EpochHeight, test_utils, base64, VMConfig
};
mod foo {
    pub(super) fn foo_fn() {}
}
mod inner {
    pub fn hello() {
        use super::ErrorKind;
        let ek = ErrorKind::NotFound;
        println!("{:?}", ek);
    }
}
fn main() {
    use self::inner;
    println!("Hello, world!");
    inner::hello();
}
#[test]
fn test_my_test() {
    use octolinker_rust_test_cases::Error;
    use crate::inner::hello;
    hello();
}