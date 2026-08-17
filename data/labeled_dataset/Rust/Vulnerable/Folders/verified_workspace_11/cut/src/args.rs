use anyhow::{self, Result, bail};
use clap::{ArgAction, Parser};
use std::env;
use std::path::PathBuf;
use std::str::FromStr;
use thiserror::Error;
#[derive(Parser)]
#[command(author, version, rename_all = "kebab-case")]
pub(crate) struct Args {
    #[arg(short, long)]
    pub feature: String,
    pub root: Option<PathBuf>,
    #[arg(short, long = "dir")]
    pub directories: Vec<Directory>,
    #[arg(short, long = "package")]
    pub packages: Vec<String>,
    #[arg(long="no-workspace-update", action=ArgAction::SetFalse)]
    pub workspace_update: bool,
    #[arg(long)]
    pub dry_run: bool,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) struct Directory {
    pub src: PathBuf,
    pub dst: PathBuf,
    pub suffix: Option<String>,
}
#[derive(Error, Debug)]
pub(crate) enum DirectoryParseError {
    #[error("Can't parse an existing source directory from '{0}'")]
    NoSrc(String),
    #[error("Can't parse a destination directory from '{0}'")]
    NoDst(String),
}
impl FromStr for Directory {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self> {
        let mut parts = s.split(':');
        let Some(src_part) = parts.next() else {
            bail!(DirectoryParseError::NoSrc(s.to_string()))
        };
        let Some(dst_part) = parts.next() else {
            bail!(DirectoryParseError::NoDst(s.to_string()))
        };
        let suffix = parts.next().map(|sfx| sfx.to_string());
        let cwd = env::current_dir()?;
        let src = cwd.join(src_part);
        let dst = cwd.join(dst_part);
        if !src.is_dir() {
            bail!(DirectoryParseError::NoSrc(src_part.to_string()));
        }
        Ok(Self { src, dst, suffix })
    }
}