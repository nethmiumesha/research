pub mod generic {
    use near_sdk::{env, log, CryptoHash, PromiseResult};
    pub type FormattedNearString = String;
    const YOCTO_FACTOR: u128 = u128::pow(10, 24);
    pub const DEFAULT_DECIMAL_PLACES: u32 = 4;
    pub fn did_promise_succeed() -> bool {
        if env::promise_results_count() != 1 {
            log!("Expected a result on the callback");
            return false;
        }
        matches!(env::promise_result(0), PromiseResult::Successful(_))
    }
    pub(crate) fn hash_account_id(account_id: &String) -> CryptoHash {
        env::sha256_array(account_id.as_bytes())
    }
    pub(crate) fn yocto_to_near(amount_in_yocto: &u128, decimal_places: u32) -> f64 {
        let precision_multiplier = u128::pow(10, decimal_places);
        let formatted_near = amount_in_yocto * precision_multiplier / YOCTO_FACTOR;
        formatted_near as f64 / precision_multiplier as f64
    }
    pub fn yocto_to_near_string(yocto: &u128) -> String {
        let numeric = yocto_to_near(&yocto, DEFAULT_DECIMAL_PLACES);
        numeric.to_string() + " Ⓝ"
    }
    pub fn near_string_to_yocto(near_string: &FormattedNearString) -> u128 {
        let cleaned = near_string
            .replace(',', "")
            .replace('_', "")
            .replace(' ', "")
            .replace('Ⓝ', "");
        let near: f64 = cleaned.parse().expect("Could not convert NEAR from string to yoctoNEAR integer. Please check the formatting of your string.");
        let precision = u128::pow(10, DEFAULT_DECIMAL_PLACES);
        let padded = (near * precision as f64) as u128 * YOCTO_FACTOR;
        let yocto = padded as u128 / precision;
        yocto
    }
}