use {
    crate::{
        curve::{base::SwapCurve, fees::Fees},
        error::SwapError,
    },
    arrayref::{array_mut_ref, array_ref, array_refs, mut_array_refs},
    enum_dispatch::enum_dispatch,
    solana_program::{
        account_info::AccountInfo,
        msg,
        program_error::ProgramError,
        program_pack::{IsInitialized, Pack, Sealed},
        pubkey::Pubkey,
    },
    spl_token_2022::{
        extension::StateWithExtensions,
        state::{Account, AccountState},
    },
    std::sync::Arc,
};
#[enum_dispatch]
pub trait SwapState {
    fn is_initialized(&self) -> bool;
    fn bump_seed(&self) -> u8;
    fn token_program_id(&self) -> &Pubkey;
    fn token_a_account(&self) -> &Pubkey;
    fn token_b_account(&self) -> &Pubkey;
    fn pool_mint(&self) -> &Pubkey;
    fn token_a_mint(&self) -> &Pubkey;
    fn token_b_mint(&self) -> &Pubkey;
    fn pool_fee_account(&self) -> &Pubkey;
    fn check_pool_fee_info(&self, pool_fee_info: &AccountInfo) -> Result<(), ProgramError>;
    fn fees(&self) -> &Fees;
    fn swap_curve(&self) -> &SwapCurve;
}
#[enum_dispatch(SwapState)]
pub enum SwapVersion {
    SwapV1,
}
impl SwapVersion {
    pub const LATEST_LEN: usize = 1 + SwapV1::LEN;
    pub fn pack(src: Self, dst: &mut [u8]) -> Result<(), ProgramError> {
        match src {
            Self::SwapV1(swap_info) => {
                dst[0] = 1;
                SwapV1::pack(swap_info, &mut dst[1..])
            }
        }
    }
    pub fn unpack(input: &[u8]) -> Result<Arc<dyn SwapState>, ProgramError> {
        let (&version, rest) = input
            .split_first()
            .ok_or(ProgramError::InvalidAccountData)?;
        match version {
            1 => Ok(Arc::new(SwapV1::unpack(rest)?)),
            _ => Err(ProgramError::UninitializedAccount),
        }
    }
    pub fn is_initialized(input: &[u8]) -> bool {
        match Self::unpack(input) {
            Ok(swap) => swap.is_initialized(),
            Err(_) => false,
        }
    }
}
#[repr(C)]
#[derive(Debug, Default, PartialEq)]
pub struct SwapV1 {
    pub is_initialized: bool,
    pub bump_seed: u8,
    pub token_program_id: Pubkey,
    pub token_a: Pubkey,
    pub token_b: Pubkey,
    pub pool_mint: Pubkey,
    pub token_a_mint: Pubkey,
    pub token_b_mint: Pubkey,
    pub pool_fee_account: Pubkey,
    pub fees: Fees,
    pub swap_curve: SwapCurve,
}
impl SwapState for SwapV1 {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
    fn bump_seed(&self) -> u8 {
        self.bump_seed
    }
    fn token_program_id(&self) -> &Pubkey {
        &self.token_program_id
    }
    fn token_a_account(&self) -> &Pubkey {
        &self.token_a
    }
    fn token_b_account(&self) -> &Pubkey {
        &self.token_b
    }
    fn pool_mint(&self) -> &Pubkey {
        &self.pool_mint
    }
    fn token_a_mint(&self) -> &Pubkey {
        &self.token_a_mint
    }
    fn token_b_mint(&self) -> &Pubkey {
        &self.token_b_mint
    }
    fn pool_fee_account(&self) -> &Pubkey {
        &self.pool_fee_account
    }
    fn check_pool_fee_info(&self, pool_fee_info: &AccountInfo) -> Result<(), ProgramError> {
        let data = &pool_fee_info.data.borrow();
        let token_account =
            StateWithExtensions::<Account>::unpack(data).map_err(|err| match err {
                ProgramError::InvalidAccountData | ProgramError::UninitializedAccount => {
                    SwapError::InvalidFeeAccount.into()
                }
                _ => err,
            })?;
        if pool_fee_info.owner != &self.token_program_id
            || token_account.base.state != AccountState::Initialized
            || token_account.base.mint != self.pool_mint
        {
            msg!("Pool fee account is not owned by token program, is not initialized, or does not match stake pool's mint");
            return Err(SwapError::InvalidFeeAccount.into());
        }
        Ok(())
    }
    fn fees(&self) -> &Fees {
        &self.fees
    }
    fn swap_curve(&self) -> &SwapCurve {
        &self.swap_curve
    }
}
impl Sealed for SwapV1 {}
impl IsInitialized for SwapV1 {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}
impl Pack for SwapV1 {
    const LEN: usize = 323;
    fn pack_into_slice(&self, output: &mut [u8]) {
        let output = array_mut_ref![output, 0, 323];
        let (
            is_initialized,
            bump_seed,
            token_program_id,
            token_a,
            token_b,
            pool_mint,
            token_a_mint,
            token_b_mint,
            pool_fee_account,
            fees,
            swap_curve,
        ) = mut_array_refs![output, 1, 1, 32, 32, 32, 32, 32, 32, 32, 64, 33];
        is_initialized[0] = self.is_initialized as u8;
        bump_seed[0] = self.bump_seed;
        token_program_id.copy_from_slice(self.token_program_id.as_ref());
        token_a.copy_from_slice(self.token_a.as_ref());
        token_b.copy_from_slice(self.token_b.as_ref());
        pool_mint.copy_from_slice(self.pool_mint.as_ref());
        token_a_mint.copy_from_slice(self.token_a_mint.as_ref());
        token_b_mint.copy_from_slice(self.token_b_mint.as_ref());
        pool_fee_account.copy_from_slice(self.pool_fee_account.as_ref());
        self.fees.pack_into_slice(&mut fees[..]);
        self.swap_curve.pack_into_slice(&mut swap_curve[..]);
    }
    fn unpack_from_slice(input: &[u8]) -> Result<Self, ProgramError> {
        let input = array_ref![input, 0, 323];
        #[allow(clippy::ptr_offset_with_cast)]
        let (
            is_initialized,
            bump_seed,
            token_program_id,
            token_a,
            token_b,
            pool_mint,
            token_a_mint,
            token_b_mint,
            pool_fee_account,
            fees,
            swap_curve,
        ) = array_refs![input, 1, 1, 32, 32, 32, 32, 32, 32, 32, 64, 33];
        Ok(Self {
            is_initialized: match is_initialized {
                [0] => false,
                [1] => true,
                _ => return Err(ProgramError::InvalidAccountData),
            },
            bump_seed: bump_seed[0],
            token_program_id: Pubkey::new_from_array(*token_program_id),
            token_a: Pubkey::new_from_array(*token_a),
            token_b: Pubkey::new_from_array(*token_b),
            pool_mint: Pubkey::new_from_array(*pool_mint),
            token_a_mint: Pubkey::new_from_array(*token_a_mint),
            token_b_mint: Pubkey::new_from_array(*token_b_mint),
            pool_fee_account: Pubkey::new_from_array(*pool_fee_account),
            fees: Fees::unpack_from_slice(fees)?,
            swap_curve: SwapCurve::unpack_from_slice(swap_curve)?,
        })
    }
}