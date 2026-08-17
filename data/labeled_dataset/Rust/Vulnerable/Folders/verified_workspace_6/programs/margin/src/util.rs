use std::time::{SystemTime, UNIX_EPOCH};
use anchor_lang::prelude::{Clock, SolanaSysvar};
pub fn get_timestamp() -> u64 {
    #[cfg(target_arch = "bpf")]
    {
        Clock::get().unwrap().unix_timestamp as u64
    }
    #[cfg(not(target_arch = "bpf"))]
    {
        if let Ok(clock) = Clock::get() {
            clock.unix_timestamp as u64
        } else {
            let time = SystemTime::now();
            time.duration_since(UNIX_EPOCH).unwrap().as_secs()
        }
    }
}