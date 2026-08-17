use std::{
    fs, io,
    path::{Path, PathBuf},
};
use anyhow::{Result, bail};
use thiserror::Error;
#[derive(Error, Debug)]
pub(crate) enum Error {
    #[error("Path attempts to access parent of root directory: {}", .0.display())]
    ParentOfRoot(PathBuf),
    #[error("Unexpected symlink: {}", .0.display())]
    Symlink(PathBuf),
}
pub(crate) fn normalize_path<P: AsRef<Path>>(path: P) -> Result<PathBuf> {
    use std::path::Component as C;
    let mut stack = vec![];
    for component in path.as_ref().components() {
        match component {
            verbatim @ (C::Prefix(_) | C::RootDir | C::Normal(_)) => stack.push(verbatim),
            C::CurDir => {  }
            C::ParentDir => match stack.last() {
                None | Some(C::ParentDir) => {
                    stack.push(C::ParentDir);
                }
                Some(C::Normal(_)) => {
                    stack.pop();
                }
                Some(C::CurDir) => {
                    unreachable!("Component::CurDir never added to the stack");
                }
                Some(C::RootDir | C::Prefix(_)) => {
                    bail!(Error::ParentOfRoot(path.as_ref().to_path_buf()))
                }
            },
        }
    }
    Ok(stack.iter().collect())
}
pub(crate) fn path_relative_to<P, Q>(src: P, dst: Q) -> io::Result<PathBuf>
where
    P: AsRef<Path>,
    Q: AsRef<Path>,
{
    use std::path::Component as C;
    let mut src = fs::canonicalize(src)?;
    let dst = fs::canonicalize(dst)?;
    if src.is_file() {
        src.pop();
    }
    let mut s_comps = src.components().peekable();
    let mut d_comps = dst.components().peekable();
    while let (Some(s_comp), Some(d_comp)) = (s_comps.peek(), d_comps.peek()) {
        if s_comp != d_comp {
            break;
        }
        s_comps.next();
        d_comps.next();
    }
    let mut stack = vec![];
    for _ in s_comps {
        stack.push(C::ParentDir)
    }
    for comp in d_comps {
        stack.push(comp)
    }
    if stack.is_empty() {
        stack.push(C::CurDir)
    }
    Ok(stack.into_iter().collect())
}
pub(crate) fn shortest_new_prefix(path: impl AsRef<Path>) -> Option<PathBuf> {
    if path.as_ref().exists() {
        return None;
    }
    let mut path = path.as_ref().to_owned();
    let mut parent = path.clone();
    parent.pop();
    while !parent.exists() {
        parent.pop();
        path.pop();
    }
    Some(path)
}
pub(crate) fn deep_copy<P, Q, K>(src: P, dst: Q, keep: &mut K) -> Result<()>
where
    P: AsRef<Path>,
    Q: AsRef<Path>,
    K: FnMut(&Path) -> bool,
{
    let src = src.as_ref();
    let dst = dst.as_ref();
    if !keep(src) {
        return Ok(());
    }
    if src.is_file() {
        fs::create_dir_all(dst.parent().expect("files have parents"))?;
        fs::copy(src, dst)?;
        return Ok(());
    }
    if src.is_symlink() {
        bail!(Error::Symlink(src.to_path_buf()));
    }
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        deep_copy(
            src.join(entry.file_name()),
            dst.join(entry.file_name()),
            keep,
        )?
    }
    Ok(())
}