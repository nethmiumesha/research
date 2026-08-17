use anyhow::{Context, Result, bail};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::env;
use std::fmt;
use std::fs;
use std::path::{Path, PathBuf};
use thiserror::Error;
use toml::value::Value;
use toml_edit::{self, Document, Item};
use crate::args::Args;
use crate::path::{deep_copy, normalize_path, path_relative_to, shortest_new_prefix};
#[derive(Debug)]
pub(crate) struct CutPlan {
    root: PathBuf,
    directories: BTreeSet<PathBuf>,
    packages: BTreeMap<String, CutPackage>,
}
#[derive(Debug, PartialEq, Eq)]
pub(crate) struct CutPackage {
    dst_name: String,
    src_path: PathBuf,
    dst_path: PathBuf,
    ws_state: WorkspaceState,
}
#[derive(Debug, PartialEq, Eq)]
pub(crate) enum WorkspaceState {
    Member,
    Exclude,
    Unknown,
}
#[derive(Debug)]
struct Workspace {
    members: HashSet<PathBuf>,
    exclude: HashSet<PathBuf>,
}
#[derive(Error, Debug)]
pub(crate) enum Error {
    #[error("Could not find repository root, please supply one")]
    NoRoot,
    #[error("No [workspace] found at {}/Cargo.toml", .0.display())]
    NoWorkspace(PathBuf),
    #[error("Both member and exclude of [workspace]: {}", .0.display())]
    WorkspaceConflict(PathBuf),
    #[error("Packages '{0}' and '{1}' map to the same cut package name")]
    PackageConflictName(String, String),
    #[error("Packages '{0}' and '{1}' map to the same cut package path")]
    PackageConflictPath(String, String),
    #[error("Cutting package '{0}' will overwrite existing path: {}", .1.display())]
    ExistingPackage(String, PathBuf),
    #[error("'{0}' field is not an array of strings")]
    NotAStringArray(&'static str),
    #[error("Cannot represent path as a TOML string: {}", .0.display())]
    PathToTomlStr(PathBuf),
}
impl CutPlan {
    pub(crate) fn discover(args: Args) -> Result<Self> {
        let cwd = env::current_dir()?;
        let Some(root) = args.root.or_else(|| discover_root(cwd)) else {
            bail!(Error::NoRoot);
        };
        let root = fs::canonicalize(root)?;
        struct Walker {
            feature: String,
            ws: Option<Workspace>,
            planned_packages: BTreeMap<String, CutPackage>,
            pending_packages: HashSet<String>,
            make_directories: BTreeSet<PathBuf>,
        }
        impl Walker {
            fn walk(
                &mut self,
                src: &Path,
                dst: &Path,
                suffix: &Option<String>,
                mut fresh_parent: bool,
            ) -> Result<()> {
                self.try_insert_package(src, dst, suffix)
                    .with_context(|| format!("Failed to plan copy for {}", src.display()))?;
                if !fresh_parent && !dst.exists() {
                    self.make_directories.insert(dst.to_owned());
                    fresh_parent = true;
                }
                for entry in fs::read_dir(src)? {
                    let entry = entry?;
                    if !entry.file_type()?.is_dir() {
                        continue;
                    }
                    if entry.file_name() == "target" {
                        continue;
                    }
                    self.walk(
                        &src.join(entry.file_name()),
                        &dst.join(entry.file_name()),
                        suffix,
                        fresh_parent,
                    )?;
                }
                Ok(())
            }
            fn try_insert_package(
                &mut self,
                src: &Path,
                dst: &Path,
                suffix: &Option<String>,
            ) -> Result<()> {
                let toml = src.join("Cargo.toml");
                let Some(pkg_name) = package_name(toml)? else {
                    return Ok(());
                };
                if !self.pending_packages.remove(&pkg_name) {
                    return Ok(());
                }
                let mut dst_name = suffix
                    .as_ref()
                    .and_then(|s| pkg_name.strip_suffix(s))
                    .unwrap_or(&pkg_name)
                    .to_string();
                dst_name.push('-');
                dst_name.push_str(&self.feature);
                let dst_path = dst.to_path_buf();
                if dst_path.exists() {
                    bail!(Error::ExistingPackage(pkg_name, dst_path));
                }
                self.planned_packages.insert(
                    pkg_name,
                    CutPackage {
                        dst_name,
                        dst_path,
                        src_path: src.to_path_buf(),
                        ws_state: if let Some(ws) = &self.ws {
                            ws.state(src)?
                        } else {
                            WorkspaceState::Unknown
                        },
                    },
                );
                Ok(())
            }
        }
        let mut walker = Walker {
            feature: args.feature,
            ws: if args.workspace_update {
                Some(Workspace::read(&root)?)
            } else {
                None
            },
            planned_packages: BTreeMap::new(),
            pending_packages: args.packages.into_iter().collect(),
            make_directories: BTreeSet::new(),
        };
        for dir in args.directories {
            let src_path = fs::canonicalize(&dir.src)
                .with_context(|| format!("Canonicalizing {} failed", dir.src.display()))?;
            let dst_path = normalize_path(&dir.dst)
                .with_context(|| format!("Normalizing {} failed", dir.dst.display()))?;
            let fresh_parent = shortest_new_prefix(&dst_path).is_some_and(|pfx| {
                walker.make_directories.insert(pfx);
                true
            });
            walker
                .walk(
                    &fs::canonicalize(dir.src)?,
                    &dst_path,
                    &dir.suffix,
                    fresh_parent,
                )
                .with_context(|| format!("Failed to find packages in {}", src_path.display()))?;
        }
        for pending in &walker.pending_packages {
            eprintln!("WARNING: Package '{pending}' not found during scan.");
        }
        let Walker {
            planned_packages: packages,
            make_directories: directories,
            ..
        } = walker;
        let mut rev_name = HashMap::new();
        let mut rev_path = HashMap::new();
        for (name, pkg) in &packages {
            if let Some(prev) = rev_name.insert(pkg.dst_name.clone(), name.clone()) {
                bail!(Error::PackageConflictName(name.clone(), prev));
            }
            if let Some(prev) = rev_path.insert(pkg.dst_path.clone(), name.clone()) {
                bail!(Error::PackageConflictPath(name.clone(), prev));
            }
        }
        Ok(Self {
            root,
            packages,
            directories,
        })
    }
    pub(crate) fn execute(&self) -> Result<()> {
        self.execute_().inspect_err(|_| {
            self.rollback();
        })
    }
    fn execute_(&self) -> Result<()> {
        for (name, package) in &self.packages {
            self.copy_package(package).with_context(|| {
                format!("Failed to copy package '{name}' to '{}'.", package.dst_name)
            })?
        }
        for package in self.packages.values() {
            self.update_package(package)
                .with_context(|| format!("Failed to update manifest for '{}'", package.dst_name))?
        }
        self.update_workspace()
            .context("Failed to update [workspace].")
    }
    fn copy_package(&self, package: &CutPackage) -> Result<()> {
        deep_copy(&package.src_path, &package.dst_path, &mut |src| {
            src.is_file() || !src.ends_with("target")
        })?;
        Ok(())
    }
    fn update_package(&self, package: &CutPackage) -> Result<()> {
        let path = package.dst_path.join("Cargo.toml");
        let mut toml = fs::read_to_string(&path)?.parse::<Document>()?;
        toml["package"]["name"] = toml_edit::value(&package.dst_name);
        self.update_dependencies(&package.src_path, &package.dst_path, toml.as_table_mut())?;
        if let Some(targets) = toml.get_mut("target").and_then(Item::as_table_like_mut) {
            for (_, target) in targets.iter_mut() {
                if let Some(target) = target.as_table_like_mut() {
                    self.update_dependencies(&package.src_path, &package.dst_path, target)?;
                };
            }
        };
        fs::write(&path, toml.to_string())?;
        Ok(())
    }
    fn update_dependencies(
        &self,
        src_path: impl AsRef<Path>,
        dst_path: impl AsRef<Path>,
        table: &mut dyn toml_edit::TableLike,
    ) -> Result<()> {
        for field in ["dependencies", "dev-dependencies", "build-dependencies"] {
            let Some(deps) = table.get_mut(field).and_then(Item::as_table_like_mut) else {
                continue;
            };
            for (dep_name, dep) in deps.iter_mut() {
                self.update_dependency(&src_path, &dst_path, dep_name, dep)?
            }
        }
        Ok(())
    }
    fn update_dependency(
        &self,
        src_path: impl AsRef<Path>,
        dst_path: impl AsRef<Path>,
        dep_name: toml_edit::KeyMut,
        dep: &mut Item,
    ) -> Result<()> {
        let Some(dep) = dep.as_table_like_mut() else {
            return Ok(());
        };
        let dep_pkg = self.packages.get(
            dep.get("package")
                .and_then(Item::as_str)
                .unwrap_or_else(|| dep_name.get()),
        );
        let Some(path) = dep.get_mut("path") else {
            return Ok(());
        };
        if let Some(dep_pkg) = dep_pkg {
            *path = toml_edit::value(path_to_toml_value(dst_path, &dep_pkg.dst_path)?);
            if dep_name.get() != dep_pkg.dst_name {
                dep.insert("package", toml_edit::value(&dep_pkg.dst_name));
            }
        } else if let Some(rel_dep_path) = path.as_str() {
            let dep_path = src_path.as_ref().join(rel_dep_path);
            *path = toml_edit::value(path_to_toml_value(dst_path, dep_path)?);
        }
        Ok(())
    }
    fn update_workspace(&self) -> Result<()> {
        let path = self.root.join("Cargo.toml");
        if !path.exists() {
            bail!(Error::NoWorkspace(path));
        }
        let mut toml = fs::read_to_string(&path)?.parse::<Document>()?;
        for package in self.packages.values() {
            match package.ws_state {
                WorkspaceState::Unknown => {
                    continue;
                }
                WorkspaceState::Member => {
                    let Some(members) = toml["workspace"]["members"].as_array_mut() else {
                        bail!(Error::NotAStringArray("members"));
                    };
                    let pkg_path = path_to_toml_value(&self.root, &package.dst_path)?;
                    members.push(pkg_path);
                }
                WorkspaceState::Exclude => {
                    let Some(exclude) = toml["workspace"]["exclude"].as_array_mut() else {
                        bail!(Error::NotAStringArray("exclude"));
                    };
                    let pkg_path = path_to_toml_value(&self.root, &package.dst_path)?;
                    exclude.push(pkg_path);
                }
            };
        }
        if let Some(members) = toml
            .get_mut("workspace")
            .and_then(|w| w.get_mut("members"))
            .and_then(|m| m.as_array_mut())
        {
            format_array_of_strings("members", members)?
        }
        if let Some(exclude) = toml
            .get_mut("workspace")
            .and_then(|w| w.get_mut("exclude"))
            .and_then(|m| m.as_array_mut())
        {
            format_array_of_strings("exclude", exclude)?
        }
        fs::write(&path, toml.to_string())?;
        Ok(())
    }
    fn rollback(&self) {
        for dir in &self.directories {
            if let Err(e) = fs::remove_dir_all(dir) {
                eprintln!("Rollback Error deleting {}: {e}", dir.display());
            }
        }
    }
}
impl Workspace {
    fn read<P: AsRef<Path>>(root: P) -> Result<Self> {
        let path = root.as_ref().join("Cargo.toml");
        if !path.exists() {
            bail!(Error::NoWorkspace(path));
        }
        let toml = toml::de::from_str::<Value>(&fs::read_to_string(&path)?)?;
        let Some(workspace) = toml.get("workspace") else {
            bail!(Error::NoWorkspace(path));
        };
        let members = toml_path_array_to_set(root.as_ref(), workspace, "members")
            .context("Failed to read workspace.members")?;
        let exclude = toml_path_array_to_set(root.as_ref(), workspace, "exclude")
            .context("Failed to read workspace.exclude")?;
        Ok(Self { members, exclude })
    }
    fn state<P: AsRef<Path>>(&self, path: P) -> Result<WorkspaceState> {
        let path = path.as_ref();
        match (self.members.contains(path), self.exclude.contains(path)) {
            (true, true) => bail!(Error::WorkspaceConflict(path.to_path_buf())),
            (true, false) => Ok(WorkspaceState::Member),
            (false, true) => Ok(WorkspaceState::Exclude),
            (false, false) => Ok(WorkspaceState::Unknown),
        }
    }
}
impl fmt::Display for CutPlan {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        writeln!(f, "Copying packages in: {}", self.root.display())?;
        fn write_package(
            root: &Path,
            name: &str,
            pkg: &CutPackage,
            f: &mut fmt::Formatter<'_>,
        ) -> fmt::Result {
            let dst_path = pkg.dst_path.strip_prefix(root).unwrap_or(&pkg.dst_path);
            let src_path = pkg.src_path.strip_prefix(root).unwrap_or(&pkg.src_path);
            writeln!(f, " - to:   {}", pkg.dst_name)?;
            writeln!(f, "         {}", dst_path.display())?;
            writeln!(f, "   from: {name}")?;
            writeln!(f, "         {}", src_path.display())?;
            Ok(())
        }
        writeln!(f)?;
        writeln!(f, "new [workspace] members:")?;
        for (name, package) in &self.packages {
            if package.ws_state == WorkspaceState::Member {
                write_package(&self.root, name, package, f)?
            }
        }
        writeln!(f)?;
        writeln!(f, "new [workspace] excludes:")?;
        for (name, package) in &self.packages {
            if package.ws_state == WorkspaceState::Exclude {
                write_package(&self.root, name, package, f)?
            }
        }
        writeln!(f)?;
        writeln!(f, "other packages:")?;
        for (name, package) in &self.packages {
            if package.ws_state == WorkspaceState::Unknown {
                write_package(&self.root, name, package, f)?
            }
        }
        Ok(())
    }
}
fn discover_root(mut cwd: PathBuf) -> Option<PathBuf> {
    cwd.extend(["_", ".git"]);
    while {
        cwd.pop();
        cwd.pop()
    } {
        cwd.push(".git");
        if cwd.is_dir() {
            cwd.pop();
            return Some(cwd);
        }
    }
    None
}
fn toml_path_array_to_set<P: AsRef<Path>>(
    root: P,
    table: &Value,
    field: &'static str,
) -> Result<HashSet<PathBuf>> {
    let mut set = HashSet::new();
    let Some(array) = table.get(field) else {
        return Ok(set);
    };
    let Some(array) = array.as_array() else {
        bail!(Error::NotAStringArray(field))
    };
    for val in array {
        let Some(path) = val.as_str() else {
            bail!(Error::NotAStringArray(field));
        };
        set.insert(
            fs::canonicalize(root.as_ref().join(path))
                .with_context(|| format!("Canonicalizing path '{path}'"))?,
        );
    }
    Ok(set)
}
fn path_to_toml_value<P, Q>(root: P, path: Q) -> Result<toml_edit::Value>
where
    P: AsRef<Path>,
    Q: AsRef<Path>,
{
    let path = path_relative_to(root, path)?;
    let Some(repr) = path.to_str() else {
        bail!(Error::PathToTomlStr(path));
    };
    Ok(repr.into())
}
fn format_array_of_strings(field: &'static str, array: &mut toml_edit::Array) -> Result<()> {
    let mut strs = BTreeSet::new();
    for item in &*array {
        let Some(s) = item.as_str() else {
            bail!(Error::NotAStringArray(field));
        };
        strs.insert(s.to_owned());
    }
    array.set_trailing_comma(true);
    array.set_trailing("\n");
    array.clear();
    for s in strs {
        array.push_formatted(toml_edit::Value::from(s).decorated("\n    ", ""));
    }
    Ok(())
}
fn package_name<P: AsRef<Path>>(path: P) -> Result<Option<String>> {
    if !path.as_ref().is_file() {
        return Ok(None);
    }
    let content = fs::read_to_string(&path)?;
    let toml = toml::de::from_str::<Value>(&content)?;
    let Some(package) = toml.get("package") else {
        return Ok(None);
    };
    let Some(name) = package.get("name") else {
        return Ok(None);
    };
    Ok(name.as_str().map(str::to_string))
}