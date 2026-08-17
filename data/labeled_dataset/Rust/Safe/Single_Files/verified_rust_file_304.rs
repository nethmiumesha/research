use crate::{slot::Slot, standard::nep297::Event, DefaultStorageKey};
use near_sdk::require;
use near_sdk_contract_tools_macros::event;
const UNPAUSED_FAIL_MESSAGE: &str = "Disallowed while contract is unpaused";
const PAUSED_FAIL_MESSAGE: &str = "Disallowed while contract is paused";
#[event(
    standard = "x-paus",
    version = "1.0.0",
    crate = "crate",
    macros = "near_sdk_contract_tools_macros"
)]
#[derive(Debug, Clone)]
pub enum PauseEvent {
    Pause,
    Unpause,
}
pub trait PauseInternal {
    #[must_use]
    fn root() -> Slot<()> {
        Slot::new(DefaultStorageKey::Pause)
    }
    #[must_use]
    fn slot_paused() -> Slot<bool> {
        Self::root().transmute()
    }
}
pub trait Pause {
    fn set_is_paused(&mut self, is_paused: bool);
    fn is_paused() -> bool;
    fn pause(&mut self);
    fn unpause(&mut self);
    fn require_paused();
    fn require_unpaused();
}
impl<T: PauseInternal> Pause for T {
    fn set_is_paused(&mut self, is_paused: bool) {
        Self::slot_paused().write(&is_paused);
    }
    fn is_paused() -> bool {
        Self::slot_paused().read().unwrap_or(false)
    }
    fn pause(&mut self) {
        Self::require_unpaused();
        self.set_is_paused(true);
        PauseEvent::Pause.emit();
    }
    fn unpause(&mut self) {
        Self::require_paused();
        self.set_is_paused(false);
        PauseEvent::Unpause.emit();
    }
    fn require_paused() {
        require!(Self::is_paused(), UNPAUSED_FAIL_MESSAGE);
    }
    fn require_unpaused() {
        require!(!Self::is_paused(), PAUSED_FAIL_MESSAGE);
    }
}
mod ext {
    #![allow(missing_docs)]
    use near_sdk::ext_contract;
    #[ext_contract(ext_pause)]
    pub trait PauseExternal {
        fn paus_is_paused(&self) -> bool;
    }
}
pub use ext::*;
pub mod hooks {
    use crate::hook::Hook;
    use super::Pause;
    pub struct Pausable;
    impl<C, A> Hook<C, A> for Pausable
    where
        C: Pause,
    {
        fn hook<R>(contract: &mut C, _args: &A, f: impl FnOnce(&mut C) -> R) -> R {
            C::require_unpaused();
            f(contract)
        }
    }
}