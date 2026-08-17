use {
    crate::error::LendingError,
    solana_program::{clock::Slot, program_error::ProgramError},
    std::cmp::Ordering,
};
pub const STALE_AFTER_SLOTS_ELAPSED: u64 = 1;
#[derive(Clone, Debug, Default)]
pub struct LastUpdate {
    pub slot: Slot,
    pub stale: bool,
}
impl LastUpdate {
    pub fn new(slot: Slot) -> Self {
        Self { slot, stale: true }
    }
    pub fn slots_elapsed(&self, slot: Slot) -> Result<u64, ProgramError> {
        let slots_elapsed = slot
            .checked_sub(self.slot)
            .ok_or(LendingError::MathOverflow)?;
        Ok(slots_elapsed)
    }
    pub fn update_slot(&mut self, slot: Slot) {
        self.slot = slot;
        self.stale = false;
    }
    pub fn mark_stale(&mut self) {
        self.stale = true;
    }
    pub fn is_stale(&self, slot: Slot) -> Result<bool, ProgramError> {
        Ok(self.stale || self.slots_elapsed(slot)? >= STALE_AFTER_SLOTS_ELAPSED)
    }
}
impl PartialEq for LastUpdate {
    fn eq(&self, other: &Self) -> bool {
        self.slot == other.slot
    }
}
impl PartialOrd for LastUpdate {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.slot.partial_cmp(&other.slot)
    }
}