use {
    super::*,
    arrayref::{array_mut_ref, array_ref, array_refs, mut_array_refs},
    solana_program::{
        msg,
        program_error::ProgramError,
        program_pack::{IsInitialized, Pack, Sealed},
        pubkey::{Pubkey, PUBKEY_BYTES},
    },
};
#[derive(Clone, Debug, Default, PartialEq)]
pub struct LendingMarket {
    pub version: u8,
    pub bump_seed: u8,
    pub owner: Pubkey,
    pub quote_currency: [u8; 32],
    pub token_program_id: Pubkey,
    pub oracle_program_id: Pubkey,
}
impl LendingMarket {
    pub fn new(params: InitLendingMarketParams) -> Self {
        let mut lending_market = Self::default();
        Self::init(&mut lending_market, params);
        lending_market
    }
    pub fn init(&mut self, params: InitLendingMarketParams) {
        self.version = PROGRAM_VERSION;
        self.bump_seed = params.bump_seed;
        self.owner = params.owner;
        self.quote_currency = params.quote_currency;
        self.token_program_id = params.token_program_id;
        self.oracle_program_id = params.oracle_program_id;
    }
}
pub struct InitLendingMarketParams {
    pub bump_seed: u8,
    pub owner: Pubkey,
    pub quote_currency: [u8; 32],
    pub token_program_id: Pubkey,
    pub oracle_program_id: Pubkey,
}
impl Sealed for LendingMarket {}
impl IsInitialized for LendingMarket {
    fn is_initialized(&self) -> bool {
        self.version != UNINITIALIZED_VERSION
    }
}
const LENDING_MARKET_LEN: usize = 258;
impl Pack for LendingMarket {
    const LEN: usize = LENDING_MARKET_LEN;
    fn pack_into_slice(&self, output: &mut [u8]) {
        let output = array_mut_ref![output, 0, LENDING_MARKET_LEN];
        #[allow(clippy::ptr_offset_with_cast)]
        let (
            version,
            bump_seed,
            owner,
            quote_currency,
            token_program_id,
            oracle_program_id,
            _padding,
        ) = mut_array_refs![
            output,
            1,
            1,
            PUBKEY_BYTES,
            32,
            PUBKEY_BYTES,
            PUBKEY_BYTES,
            128
        ];
        *version = self.version.to_le_bytes();
        *bump_seed = self.bump_seed.to_le_bytes();
        owner.copy_from_slice(self.owner.as_ref());
        quote_currency.copy_from_slice(self.quote_currency.as_ref());
        token_program_id.copy_from_slice(self.token_program_id.as_ref());
        oracle_program_id.copy_from_slice(self.oracle_program_id.as_ref());
    }
    fn unpack_from_slice(input: &[u8]) -> Result<Self, ProgramError> {
        let input = array_ref![input, 0, LENDING_MARKET_LEN];
        #[allow(clippy::ptr_offset_with_cast)]
        let (
            version,
            bump_seed,
            owner,
            quote_currency,
            token_program_id,
            oracle_program_id,
            _padding,
        ) = array_refs![
            input,
            1,
            1,
            PUBKEY_BYTES,
            32,
            PUBKEY_BYTES,
            PUBKEY_BYTES,
            128
        ];
        let version = u8::from_le_bytes(*version);
        if version > PROGRAM_VERSION {
            msg!("Lending market version does not match lending program version");
            return Err(ProgramError::InvalidAccountData);
        }
        Ok(Self {
            version,
            bump_seed: u8::from_le_bytes(*bump_seed),
            owner: Pubkey::new_from_array(*owner),
            quote_currency: *quote_currency,
            token_program_id: Pubkey::new_from_array(*token_program_id),
            oracle_program_id: Pubkey::new_from_array(*oracle_program_id),
        })
    }
}