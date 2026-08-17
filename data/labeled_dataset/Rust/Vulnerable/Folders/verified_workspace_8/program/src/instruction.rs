use crate::matching::{ExpiryType, OrderType, Side};
use crate::state::{AssetType, MarketMode, INFO_LEN};
use crate::state::{TriggerCondition, MAX_PAIRS};
use arrayref::{array_ref, array_refs};
use fixed::types::I80F48;
use num_enum::TryFromPrimitive;
use serde::{Deserialize, Serialize};
use solana_program::instruction::{AccountMeta, Instruction};
use solana_program::program_error::ProgramError;
use solana_program::pubkey::Pubkey;
use std::convert::{TryFrom, TryInto};
use std::num::NonZeroU64;
#[repr(C)]
#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub enum MangoInstruction {
    InitMangoGroup {
        signer_nonce: u64,
        valid_interval: u64,
        quote_optimal_util: I80F48,
        quote_optimal_rate: I80F48,
        quote_max_rate: I80F48,
    },
    InitMangoAccount,
    Deposit {
        quantity: u64,
    },
    Withdraw {
        quantity: u64,
        allow_borrow: bool,
    },
    AddSpotMarket {
        maint_leverage: I80F48,
        init_leverage: I80F48,
        liquidation_fee: I80F48,
        optimal_util: I80F48,
        optimal_rate: I80F48,
        max_rate: I80F48,
    },
    AddToBasket {
        market_index: usize,
    },
    Borrow {
        quantity: u64,
    },
    CachePrices,
    CacheRootBanks,
    PlaceSpotOrder {
        order: serum_dex::instruction::NewOrderInstructionV3,
    },
    AddOracle,
    AddPerpMarket {
        maint_leverage: I80F48,
        init_leverage: I80F48,
        liquidation_fee: I80F48,
        maker_fee: I80F48,
        taker_fee: I80F48,
        base_lot_size: i64,
        quote_lot_size: i64,
        rate: I80F48,
        max_depth_bps: I80F48,
        target_period_length: u64,
        mngo_per_period: u64,
        exp: u8,
    },
    PlacePerpOrder {
        price: i64,
        quantity: i64,
        client_order_id: u64,
        side: Side,
        order_type: OrderType,
        reduce_only: bool,
    },
    CancelPerpOrderByClientId {
        client_order_id: u64,
        invalid_id_ok: bool,
    },
    CancelPerpOrder {
        order_id: i128,
        invalid_id_ok: bool,
    },
    ConsumeEvents {
        limit: usize,
    },
    CachePerpMarkets,
    UpdateFunding,
    SetOracle {
        price: I80F48,
    },
    SettleFunds,
    CancelSpotOrder {
        order: serum_dex::instruction::CancelOrderInstructionV2,
    },
    UpdateRootBank,
    SettlePnl {
        market_index: usize,
    },
    SettleBorrow {
        token_index: usize,
        quantity: u64,
    },
    ForceCancelSpotOrders {
        limit: u8,
    },
    ForceCancelPerpOrders {
        limit: u8,
    },
    LiquidateTokenAndToken {
        max_liab_transfer: I80F48,
    },
    LiquidateTokenAndPerp {
        asset_type: AssetType,
        asset_index: usize,
        liab_type: AssetType,
        liab_index: usize,
        max_liab_transfer: I80F48,
    },
    LiquidatePerpMarket {
        base_transfer_request: i64,
    },
    SettleFees,
    ResolvePerpBankruptcy {
        liab_index: usize,
        max_liab_transfer: I80F48,
    },
    ResolveTokenBankruptcy {
        max_liab_transfer: I80F48,
    },
    InitSpotOpenOrders,
    RedeemMngo,
    AddMangoAccountInfo {
        info: [u8; INFO_LEN],
    },
    DepositMsrm {
        quantity: u64,
    },
    WithdrawMsrm {
        quantity: u64,
    },
    ChangePerpMarketParams {
        #[serde(serialize_with = "serialize_option_fixed_width")]
        maint_leverage: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        init_leverage: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        liquidation_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        maker_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        taker_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        rate: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        max_depth_bps: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        target_period_length: Option<u64>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        mngo_per_period: Option<u64>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        exp: Option<u8>,
    },
    SetGroupAdmin,
    CancelAllPerpOrders {
        limit: u8,
    },
    ForceSettleQuotePositions,
    PlaceSpotOrder2 {
        order: serum_dex::instruction::NewOrderInstructionV3,
    },
    InitAdvancedOrders,
    AddPerpTriggerOrder {
        order_type: OrderType,
        side: Side,
        trigger_condition: TriggerCondition,
        reduce_only: bool,
        client_order_id: u64,
        price: i64,
        quantity: i64,
        trigger_price: I80F48,
    },
    RemoveAdvancedOrder {
        order_index: u8,
    },
    ExecutePerpTriggerOrder {
        order_index: u8,
    },
    CreatePerpMarket {
        maint_leverage: I80F48,
        init_leverage: I80F48,
        liquidation_fee: I80F48,
        maker_fee: I80F48,
        taker_fee: I80F48,
        base_lot_size: i64,
        quote_lot_size: i64,
        rate: I80F48,
        max_depth_bps: I80F48,
        target_period_length: u64,
        mngo_per_period: u64,
        exp: u8,
        version: u8,
        lm_size_shift: u8,
        base_decimals: u8,
    },
    ChangePerpMarketParams2 {
        #[serde(serialize_with = "serialize_option_fixed_width")]
        maint_leverage: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        init_leverage: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        liquidation_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        maker_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        taker_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        rate: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        max_depth_bps: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        target_period_length: Option<u64>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        mngo_per_period: Option<u64>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        exp: Option<u8>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        version: Option<u8>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        lm_size_shift: Option<u8>,
    },
    UpdateMarginBasket,
    ChangeMaxMangoAccounts {
        max_mango_accounts: u32,
    },
    CloseMangoAccount,
    CloseSpotOpenOrders,
    CloseAdvancedOrders,
    CreateDustAccount,
    ResolveDust,
    CreateMangoAccount {
        account_num: u64,
    },
    UpgradeMangoAccountV0V1,
    CancelPerpOrdersSide {
        side: Side,
        limit: u8,
    },
    SetDelegate,
    ChangeSpotMarketParams {
        #[serde(serialize_with = "serialize_option_fixed_width")]
        maint_leverage: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        init_leverage: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        liquidation_fee: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        optimal_util: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        optimal_rate: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        max_rate: Option<I80F48>,
        #[serde(serialize_with = "serialize_option_fixed_width")]
        version: Option<u8>,
    },
    CreateSpotOpenOrders,
    ChangeReferralFeeParams {
        ref_surcharge_centibps: u32,
        ref_share_centibps: u32,
        ref_mngo_required: u64,
    },
    SetReferrerMemory,
    RegisterReferrerId {
        referrer_id: [u8; INFO_LEN],
    },
    PlacePerpOrder2 {
        price: i64,
        max_base_quantity: i64,
        max_quote_quantity: i64,
        client_order_id: u64,
        expiry_timestamp: u64,
        side: Side,
        order_type: OrderType,
        reduce_only: bool,
        limit: u8,
        expiry_type: ExpiryType,
    },
    CancelAllSpotOrders {
        limit: u8,
    },
    Withdraw2 {
        quantity: u64,
        allow_borrow: bool,
    },
    SetMarketMode {
        market_index: usize,
        mode: MarketMode,
        market_type: AssetType,
    },
    RemovePerpMarket,
    SwapSpotMarket,
    RemoveSpotMarket,
    RemoveOracle,
    LiquidateDelistingToken {
        max_liquidate_amount: u64,
    },
    ForceSettlePerpPosition,
    ChangeReferralFeeParams2 {
        ref_surcharge_centibps_tier_1: u32,
        ref_share_centibps_tier_1: u32,
        ref_surcharge_centibps_tier_2: u16,
        ref_share_centibps_tier_2: u16,
        ref_mngo_required: u64,
        ref_mngo_tier_2_factor: u8,
    },
    RecoveryForceSettleSpotOrders {
        limit: u8,
    },
    RecoveryWithdrawTokenVault,
    RecoveryWithdrawMngoVault,
    RecoveryWithdrawInsuranceVault,
}
impl MangoInstruction {
    pub fn unpack(input: &[u8]) -> Option<Self> {
        let (&discrim, data) = array_refs![input, 4; ..;];
        let discrim = u32::from_le_bytes(discrim);
        Some(match discrim {
            0 => {
                let data = array_ref![data, 0, 64];
                let (
                    signer_nonce,
                    valid_interval,
                    quote_optimal_util,
                    quote_optimal_rate,
                    quote_max_rate,
                ) = array_refs![data, 8, 8, 16, 16, 16];
                MangoInstruction::InitMangoGroup {
                    signer_nonce: u64::from_le_bytes(*signer_nonce),
                    valid_interval: u64::from_le_bytes(*valid_interval),
                    quote_optimal_util: I80F48::from_le_bytes(*quote_optimal_util),
                    quote_optimal_rate: I80F48::from_le_bytes(*quote_optimal_rate),
                    quote_max_rate: I80F48::from_le_bytes(*quote_max_rate),
                }
            }
            1 => MangoInstruction::InitMangoAccount,
            2 => {
                let quantity = array_ref![data, 0, 8];
                MangoInstruction::Deposit { quantity: u64::from_le_bytes(*quantity) }
            }
            3 => {
                let data = array_ref![data, 0, 9];
                let (quantity, allow_borrow) = array_refs![data, 8, 1];
                let allow_borrow = match allow_borrow {
                    [0] => false,
                    [1] => true,
                    _ => return None,
                };
                MangoInstruction::Withdraw { quantity: u64::from_le_bytes(*quantity), allow_borrow }
            }
            4 => {
                let data = array_ref![data, 0, 96];
                let (
                    maint_leverage,
                    init_leverage,
                    liquidation_fee,
                    optimal_util,
                    optimal_rate,
                    max_rate,
                ) = array_refs![data, 16, 16, 16, 16, 16, 16];
                MangoInstruction::AddSpotMarket {
                    maint_leverage: I80F48::from_le_bytes(*maint_leverage),
                    init_leverage: I80F48::from_le_bytes(*init_leverage),
                    liquidation_fee: I80F48::from_le_bytes(*liquidation_fee),
                    optimal_util: I80F48::from_le_bytes(*optimal_util),
                    optimal_rate: I80F48::from_le_bytes(*optimal_rate),
                    max_rate: I80F48::from_le_bytes(*max_rate),
                }
            }
            5 => {
                let market_index = array_ref![data, 0, 8];
                MangoInstruction::AddToBasket { market_index: usize::from_le_bytes(*market_index) }
            }
            6 => {
                let quantity = array_ref![data, 0, 8];
                MangoInstruction::Borrow { quantity: u64::from_le_bytes(*quantity) }
            }
            7 => MangoInstruction::CachePrices,
            8 => MangoInstruction::CacheRootBanks,
            9 => {
                let order = unpack_dex_new_order_v3(data)?;
                MangoInstruction::PlaceSpotOrder { order }
            }
            10 => MangoInstruction::AddOracle,
            11 => {
                let exp = if data.len() > 144 { data[144] } else { 2 };
                let data_arr = array_ref![data, 0, 144];
                let (
                    maint_leverage,
                    init_leverage,
                    liquidation_fee,
                    maker_fee,
                    taker_fee,
                    base_lot_size,
                    quote_lot_size,
                    rate,
                    max_depth_bps,
                    target_period_length,
                    mngo_per_period,
                ) = array_refs![data_arr, 16, 16, 16, 16, 16, 8, 8, 16, 16, 8, 8];
                MangoInstruction::AddPerpMarket {
                    maint_leverage: I80F48::from_le_bytes(*maint_leverage),
                    init_leverage: I80F48::from_le_bytes(*init_leverage),
                    liquidation_fee: I80F48::from_le_bytes(*liquidation_fee),
                    maker_fee: I80F48::from_le_bytes(*maker_fee),
                    taker_fee: I80F48::from_le_bytes(*taker_fee),
                    base_lot_size: i64::from_le_bytes(*base_lot_size),
                    quote_lot_size: i64::from_le_bytes(*quote_lot_size),
                    rate: I80F48::from_le_bytes(*rate),
                    max_depth_bps: I80F48::from_le_bytes(*max_depth_bps),
                    target_period_length: u64::from_le_bytes(*target_period_length),
                    mngo_per_period: u64::from_le_bytes(*mngo_per_period),
                    exp,
                }
            }
            12 => {
                let reduce_only = if data.len() > 26 { data[26] != 0 } else { false };
                let data_arr = array_ref![data, 0, 26];
                let (price, quantity, client_order_id, side, order_type) =
                    array_refs![data_arr, 8, 8, 8, 1, 1];
                MangoInstruction::PlacePerpOrder {
                    price: i64::from_le_bytes(*price),
                    quantity: i64::from_le_bytes(*quantity),
                    client_order_id: u64::from_le_bytes(*client_order_id),
                    side: Side::try_from_primitive(side[0]).ok()?,
                    order_type: OrderType::try_from_primitive(order_type[0]).ok()?,
                    reduce_only,
                }
            }
            13 => {
                let data_arr = array_ref![data, 0, 9];
                let (client_order_id, invalid_id_ok) = array_refs![data_arr, 8, 1];
                MangoInstruction::CancelPerpOrderByClientId {
                    client_order_id: u64::from_le_bytes(*client_order_id),
                    invalid_id_ok: invalid_id_ok[0] != 0,
                }
            }
            14 => {
                let data_arr = array_ref![data, 0, 17];
                let (order_id, invalid_id_ok) = array_refs![data_arr, 16, 1];
                MangoInstruction::CancelPerpOrder {
                    order_id: i128::from_le_bytes(*order_id),
                    invalid_id_ok: invalid_id_ok[0] != 0,
                }
            }
            15 => {
                let data_arr = array_ref![data, 0, 8];
                MangoInstruction::ConsumeEvents { limit: usize::from_le_bytes(*data_arr) }
            }
            16 => MangoInstruction::CachePerpMarkets,
            17 => MangoInstruction::UpdateFunding,
            18 => {
                let data_arr = array_ref![data, 0, 16];
                MangoInstruction::SetOracle { price: I80F48::from_le_bytes(*data_arr) }
            }
            19 => MangoInstruction::SettleFunds,
            20 => {
                let data_array = array_ref![data, 0, 20];
                let fields = array_refs![data_array, 4, 16];
                let side = match u32::from_le_bytes(*fields.0) {
                    0 => serum_dex::matching::Side::Bid,
                    1 => serum_dex::matching::Side::Ask,
                    _ => return None,
                };
                let order_id = u128::from_le_bytes(*fields.1);
                let order = serum_dex::instruction::CancelOrderInstructionV2 { side, order_id };
                MangoInstruction::CancelSpotOrder { order }
            }
            21 => MangoInstruction::UpdateRootBank,
            22 => {
                let data_arr = array_ref![data, 0, 8];
                MangoInstruction::SettlePnl { market_index: usize::from_le_bytes(*data_arr) }
            }
            23 => {
                let data = array_ref![data, 0, 16];
                let (token_index, quantity) = array_refs![data, 8, 8];
                MangoInstruction::SettleBorrow {
                    token_index: usize::from_le_bytes(*token_index),
                    quantity: u64::from_le_bytes(*quantity),
                }
            }
            24 => {
                let data_arr = array_ref![data, 0, 1];
                MangoInstruction::ForceCancelSpotOrders { limit: u8::from_le_bytes(*data_arr) }
            }
            25 => {
                let data_arr = array_ref![data, 0, 1];
                MangoInstruction::ForceCancelPerpOrders { limit: u8::from_le_bytes(*data_arr) }
            }
            26 => {
                let data_arr = array_ref![data, 0, 16];
                MangoInstruction::LiquidateTokenAndToken {
                    max_liab_transfer: I80F48::from_le_bytes(*data_arr),
                }
            }
            27 => {
                let data = array_ref![data, 0, 34];
                let (asset_type, asset_index, liab_type, liab_index, max_liab_transfer) =
                    array_refs![data, 1, 8, 1, 8, 16];
                MangoInstruction::LiquidateTokenAndPerp {
                    asset_type: AssetType::try_from(u8::from_le_bytes(*asset_type)).unwrap(),
                    asset_index: usize::from_le_bytes(*asset_index),
                    liab_type: AssetType::try_from(u8::from_le_bytes(*liab_type)).unwrap(),
                    liab_index: usize::from_le_bytes(*liab_index),
                    max_liab_transfer: I80F48::from_le_bytes(*max_liab_transfer),
                }
            }
            28 => {
                let data_arr = array_ref![data, 0, 8];
                MangoInstruction::LiquidatePerpMarket {
                    base_transfer_request: i64::from_le_bytes(*data_arr),
                }
            }
            29 => MangoInstruction::SettleFees,
            30 => {
                let data = array_ref![data, 0, 24];
                let (liab_index, max_liab_transfer) = array_refs![data, 8, 16];
                MangoInstruction::ResolvePerpBankruptcy {
                    liab_index: usize::from_le_bytes(*liab_index),
                    max_liab_transfer: I80F48::from_le_bytes(*max_liab_transfer),
                }
            }
            31 => {
                let data_arr = array_ref![data, 0, 16];
                MangoInstruction::ResolveTokenBankruptcy {
                    max_liab_transfer: I80F48::from_le_bytes(*data_arr),
                }
            }
            32 => MangoInstruction::InitSpotOpenOrders,
            33 => MangoInstruction::RedeemMngo,
            34 => {
                let info = array_ref![data, 0, INFO_LEN];
                MangoInstruction::AddMangoAccountInfo { info: *info }
            }
            35 => {
                let quantity = array_ref![data, 0, 8];
                MangoInstruction::DepositMsrm { quantity: u64::from_le_bytes(*quantity) }
            }
            36 => {
                let quantity = array_ref![data, 0, 8];
                MangoInstruction::WithdrawMsrm { quantity: u64::from_le_bytes(*quantity) }
            }
            37 => {
                let exp =
                    if data.len() > 137 { unpack_u8_opt(&[data[137], data[138]]) } else { None };
                let data_arr = array_ref![data, 0, 137];
                let (
                    maint_leverage,
                    init_leverage,
                    liquidation_fee,
                    maker_fee,
                    taker_fee,
                    rate,
                    max_depth_bps,
                    target_period_length,
                    mngo_per_period,
                ) = array_refs![data_arr, 17, 17, 17, 17, 17, 17, 17, 9, 9];
                MangoInstruction::ChangePerpMarketParams {
                    maint_leverage: unpack_i80f48_opt(maint_leverage),
                    init_leverage: unpack_i80f48_opt(init_leverage),
                    liquidation_fee: unpack_i80f48_opt(liquidation_fee),
                    maker_fee: unpack_i80f48_opt(maker_fee),
                    taker_fee: unpack_i80f48_opt(taker_fee),
                    rate: unpack_i80f48_opt(rate),
                    max_depth_bps: unpack_i80f48_opt(max_depth_bps),
                    target_period_length: unpack_u64_opt(target_period_length),
                    mngo_per_period: unpack_u64_opt(mngo_per_period),
                    exp,
                }
            }
            38 => MangoInstruction::SetGroupAdmin,
            39 => {
                let data_arr = array_ref![data, 0, 1];
                MangoInstruction::CancelAllPerpOrders { limit: u8::from_le_bytes(*data_arr) }
            }
            40 => MangoInstruction::ForceSettleQuotePositions,
            41 => {
                let order = unpack_dex_new_order_v3(data)?;
                MangoInstruction::PlaceSpotOrder2 { order }
            }
            42 => MangoInstruction::InitAdvancedOrders,
            43 => {
                let data_arr = array_ref![data, 0, 44];
                let (
                    order_type,
                    side,
                    trigger_condition,
                    reduce_only,
                    client_order_id,
                    price,
                    quantity,
                    trigger_price,
                ) = array_refs![data_arr, 1, 1, 1, 1, 8, 8, 8, 16];
                MangoInstruction::AddPerpTriggerOrder {
                    order_type: OrderType::try_from_primitive(order_type[0]).ok()?,
                    side: Side::try_from_primitive(side[0]).ok()?,
                    trigger_condition: TriggerCondition::try_from(u8::from_le_bytes(
                        *trigger_condition,
                    ))
                    .unwrap(),
                    reduce_only: reduce_only[0] != 0,
                    client_order_id: u64::from_le_bytes(*client_order_id),
                    price: i64::from_le_bytes(*price),
                    quantity: i64::from_le_bytes(*quantity),
                    trigger_price: I80F48::from_le_bytes(*trigger_price),
                }
            }
            44 => {
                let order_index = array_ref![data, 0, 1][0];
                MangoInstruction::RemoveAdvancedOrder { order_index }
            }
            45 => {
                let order_index = array_ref![data, 0, 1][0];
                MangoInstruction::ExecutePerpTriggerOrder { order_index }
            }
            46 => {
                let data_arr = array_ref![data, 0, 148];
                let (
                    maint_leverage,
                    init_leverage,
                    liquidation_fee,
                    maker_fee,
                    taker_fee,
                    base_lot_size,
                    quote_lot_size,
                    rate,
                    max_depth_bps,
                    target_period_length,
                    mngo_per_period,
                    exp,
                    version,
                    lm_size_shift,
                    base_decimals,
                ) = array_refs![data_arr, 16, 16, 16, 16, 16, 8, 8, 16, 16, 8, 8, 1, 1, 1, 1];
                MangoInstruction::CreatePerpMarket {
                    maint_leverage: I80F48::from_le_bytes(*maint_leverage),
                    init_leverage: I80F48::from_le_bytes(*init_leverage),
                    liquidation_fee: I80F48::from_le_bytes(*liquidation_fee),
                    maker_fee: I80F48::from_le_bytes(*maker_fee),
                    taker_fee: I80F48::from_le_bytes(*taker_fee),
                    base_lot_size: i64::from_le_bytes(*base_lot_size),
                    quote_lot_size: i64::from_le_bytes(*quote_lot_size),
                    rate: I80F48::from_le_bytes(*rate),
                    max_depth_bps: I80F48::from_le_bytes(*max_depth_bps),
                    target_period_length: u64::from_le_bytes(*target_period_length),
                    mngo_per_period: u64::from_le_bytes(*mngo_per_period),
                    exp: exp[0],
                    version: version[0],
                    lm_size_shift: lm_size_shift[0],
                    base_decimals: base_decimals[0],
                }
            }
            47 => {
                let data_arr = array_ref![data, 0, 143];
                let (
                    maint_leverage,
                    init_leverage,
                    liquidation_fee,
                    maker_fee,
                    taker_fee,
                    rate,
                    max_depth_bps,
                    target_period_length,
                    mngo_per_period,
                    exp,
                    version,
                    lm_size_shift,
                ) = array_refs![data_arr, 17, 17, 17, 17, 17, 17, 17, 9, 9, 2, 2, 2];
                MangoInstruction::ChangePerpMarketParams2 {
                    maint_leverage: unpack_i80f48_opt(maint_leverage),
                    init_leverage: unpack_i80f48_opt(init_leverage),
                    liquidation_fee: unpack_i80f48_opt(liquidation_fee),
                    maker_fee: unpack_i80f48_opt(maker_fee),
                    taker_fee: unpack_i80f48_opt(taker_fee),
                    rate: unpack_i80f48_opt(rate),
                    max_depth_bps: unpack_i80f48_opt(max_depth_bps),
                    target_period_length: unpack_u64_opt(target_period_length),
                    mngo_per_period: unpack_u64_opt(mngo_per_period),
                    exp: unpack_u8_opt(exp),
                    version: unpack_u8_opt(version),
                    lm_size_shift: unpack_u8_opt(lm_size_shift),
                }
            }
            48 => MangoInstruction::UpdateMarginBasket,
            49 => {
                let data_arr = array_ref![data, 0, 4];
                MangoInstruction::ChangeMaxMangoAccounts {
                    max_mango_accounts: u32::from_le_bytes(*data_arr),
                }
            }
            50 => MangoInstruction::CloseMangoAccount,
            51 => MangoInstruction::CloseSpotOpenOrders,
            52 => MangoInstruction::CloseAdvancedOrders,
            53 => MangoInstruction::CreateDustAccount,
            54 => MangoInstruction::ResolveDust,
            55 => {
                let account_num = array_ref![data, 0, 8];
                MangoInstruction::CreateMangoAccount {
                    account_num: u64::from_le_bytes(*account_num),
                }
            }
            56 => MangoInstruction::UpgradeMangoAccountV0V1,
            57 => {
                let data_arr = array_ref![data, 0, 2];
                let (side, limit) = array_refs![data_arr, 1, 1];
                MangoInstruction::CancelPerpOrdersSide {
                    side: Side::try_from_primitive(side[0]).ok()?,
                    limit: u8::from_le_bytes(*limit),
                }
            }
            58 => MangoInstruction::SetDelegate,
            59 => {
                let data_arr = array_ref![data, 0, 104];
                let (
                    maint_leverage,
                    init_leverage,
                    liquidation_fee,
                    optimal_util,
                    optimal_rate,
                    max_rate,
                    version,
                ) = array_refs![data_arr, 17, 17, 17, 17, 17, 17, 2];
                MangoInstruction::ChangeSpotMarketParams {
                    maint_leverage: unpack_i80f48_opt(maint_leverage),
                    init_leverage: unpack_i80f48_opt(init_leverage),
                    liquidation_fee: unpack_i80f48_opt(liquidation_fee),
                    optimal_util: unpack_i80f48_opt(optimal_util),
                    optimal_rate: unpack_i80f48_opt(optimal_rate),
                    max_rate: unpack_i80f48_opt(max_rate),
                    version: unpack_u8_opt(version),
                }
            }
            60 => MangoInstruction::CreateSpotOpenOrders,
            61 => {
                let data = array_ref![data, 0, 16];
                let (ref_surcharge_centibps, ref_share_centibps, ref_mngo_required) =
                    array_refs![data, 4, 4, 8];
                MangoInstruction::ChangeReferralFeeParams {
                    ref_surcharge_centibps: u32::from_le_bytes(*ref_surcharge_centibps),
                    ref_share_centibps: u32::from_le_bytes(*ref_share_centibps),
                    ref_mngo_required: u64::from_le_bytes(*ref_mngo_required),
                }
            }
            62 => MangoInstruction::SetReferrerMemory,
            63 => {
                let referrer_id = array_ref![data, 0, INFO_LEN];
                MangoInstruction::RegisterReferrerId { referrer_id: *referrer_id }
            }
            64 => {
                let data_arr = array_ref![data, 0, 44];
                let (
                    price,
                    max_base_quantity,
                    max_quote_quantity,
                    client_order_id,
                    expiry_timestamp,
                    side,
                    order_type,
                    reduce_only,
                    limit,
                ) = array_refs![data_arr, 8, 8, 8, 8, 8, 1, 1, 1, 1];
                let expiry_type_byte = if data.len() > 44 { data[44] } else { 0 };
                MangoInstruction::PlacePerpOrder2 {
                    price: i64::from_le_bytes(*price),
                    max_base_quantity: i64::from_le_bytes(*max_base_quantity),
                    max_quote_quantity: i64::from_le_bytes(*max_quote_quantity),
                    client_order_id: u64::from_le_bytes(*client_order_id),
                    expiry_timestamp: u64::from_le_bytes(*expiry_timestamp),
                    side: Side::try_from_primitive(side[0]).ok()?,
                    order_type: OrderType::try_from_primitive(order_type[0]).ok()?,
                    reduce_only: reduce_only[0] != 0,
                    limit: u8::from_le_bytes(*limit),
                    expiry_type: ExpiryType::try_from_primitive(expiry_type_byte).ok()?,
                }
            }
            65 => {
                let data_arr = array_ref![data, 0, 1];
                let limit = data_arr[0];
                MangoInstruction::CancelAllSpotOrders { limit }
            }
            66 => {
                let data = array_ref![data, 0, 9];
                let (quantity, allow_borrow) = array_refs![data, 8, 1];
                let allow_borrow = match allow_borrow {
                    [0] => false,
                    [1] => true,
                    _ => return None,
                };
                MangoInstruction::Withdraw2 {
                    quantity: u64::from_le_bytes(*quantity),
                    allow_borrow,
                }
            }
            67 => {
                let data = array_ref![data, 0, 10];
                let (market_index, mode, market_type) = array_refs![data, 8, 1, 1];
                MangoInstruction::SetMarketMode {
                    market_index: usize::from_le_bytes(*market_index),
                    mode: MarketMode::try_from(u8::from_le_bytes(*mode)).unwrap(),
                    market_type: AssetType::try_from(u8::from_le_bytes(*market_type)).unwrap(),
                }
            }
            68 => MangoInstruction::RemovePerpMarket,
            69 => MangoInstruction::SwapSpotMarket,
            70 => MangoInstruction::RemoveSpotMarket,
            71 => MangoInstruction::RemoveOracle,
            72 => {
                let max_liquidate_amount = array_ref![data, 0, 8];
                MangoInstruction::LiquidateDelistingToken {
                    max_liquidate_amount: u64::from_le_bytes(*max_liquidate_amount),
                }
            }
            73 => MangoInstruction::ForceSettlePerpPosition,
            74 => {
                let data = array_ref![data, 0, 21];
                let (
                    ref_surcharge_centibps_tier_1,
                    ref_share_centibps_tier_1,
                    ref_surcharge_centibps_tier_2,
                    ref_share_centibps_tier_2,
                    ref_mngo_required,
                    ref_mngo_tier_2_factor,
                ) = array_refs![data, 4, 4, 2, 2, 8, 1];
                MangoInstruction::ChangeReferralFeeParams2 {
                    ref_surcharge_centibps_tier_1: u32::from_le_bytes(
                        *ref_surcharge_centibps_tier_1,
                    ),
                    ref_share_centibps_tier_1: u32::from_le_bytes(*ref_share_centibps_tier_1),
                    ref_surcharge_centibps_tier_2: u16::from_le_bytes(
                        *ref_surcharge_centibps_tier_2,
                    ),
                    ref_share_centibps_tier_2: u16::from_le_bytes(*ref_share_centibps_tier_2),
                    ref_mngo_required: u64::from_le_bytes(*ref_mngo_required),
                    ref_mngo_tier_2_factor: u8::from_le_bytes(*ref_mngo_tier_2_factor),
                }
            }
            75 => {
                let data_arr = array_ref![data, 0, 1];
                MangoInstruction::RecoveryForceSettleSpotOrders {
                    limit: u8::from_le_bytes(*data_arr),
                }
            }
            76 => MangoInstruction::RecoveryWithdrawTokenVault,
            77 => MangoInstruction::RecoveryWithdrawMngoVault,
            78 => MangoInstruction::RecoveryWithdrawInsuranceVault,
            _ => {
                return None;
            }
        })
    }
    pub fn pack(&self) -> Vec<u8> {
        bincode::serialize(self).unwrap()
    }
}
fn unpack_u8_opt(data: &[u8; 2]) -> Option<u8> {
    if data[0] == 0 {
        None
    } else {
        Some(data[1])
    }
}
fn unpack_i80f48_opt(data: &[u8; 17]) -> Option<I80F48> {
    let (opt, val) = array_refs![data, 1, 16];
    if opt[0] == 0 {
        None
    } else {
        Some(I80F48::from_le_bytes(*val))
    }
}
fn unpack_u64_opt(data: &[u8; 9]) -> Option<u64> {
    let (opt, val) = array_refs![data, 1, 8];
    if opt[0] == 0 {
        None
    } else {
        Some(u64::from_le_bytes(*val))
    }
}
fn unpack_dex_new_order_v3(data: &[u8]) -> Option<serum_dex::instruction::NewOrderInstructionV3> {
    let max_ts =
        if data.len() == 54 { i64::from_le_bytes(*array_ref![data, 46, 8]) } else { i64::MAX };
    let data = array_ref![data, 0, 46];
    let (
        &side_arr,
        &price_arr,
        &max_coin_qty_arr,
        &max_native_pc_qty_arr,
        &self_trade_behavior_arr,
        &otype_arr,
        &client_order_id_bytes,
        &limit_arr,
    ) = array_refs![data, 4, 8, 8, 8, 4, 4, 8, 2];
    let side = serum_dex::matching::Side::try_from_primitive(
        u32::from_le_bytes(side_arr).try_into().ok()?,
    )
    .ok()?;
    let limit_price = NonZeroU64::new(u64::from_le_bytes(price_arr))?;
    let max_coin_qty = NonZeroU64::new(u64::from_le_bytes(max_coin_qty_arr))?;
    let max_native_pc_qty_including_fees =
        NonZeroU64::new(u64::from_le_bytes(max_native_pc_qty_arr))?;
    let self_trade_behavior = serum_dex::instruction::SelfTradeBehavior::try_from_primitive(
        u32::from_le_bytes(self_trade_behavior_arr).try_into().ok()?,
    )
    .ok()?;
    let order_type = serum_dex::matching::OrderType::try_from_primitive(
        u32::from_le_bytes(otype_arr).try_into().ok()?,
    )
    .ok()?;
    let client_order_id = u64::from_le_bytes(client_order_id_bytes);
    let limit = u16::from_le_bytes(limit_arr);
    Some(serum_dex::instruction::NewOrderInstructionV3 {
        side,
        limit_price,
        max_coin_qty,
        max_native_pc_qty_including_fees,
        self_trade_behavior,
        order_type,
        client_order_id,
        limit,
        max_ts,
    })
}
pub fn init_mango_group(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    signer_pk: &Pubkey,
    admin_pk: &Pubkey,
    quote_mint_pk: &Pubkey,
    quote_vault_pk: &Pubkey,
    quote_node_bank_pk: &Pubkey,
    quote_root_bank_pk: &Pubkey,
    insurance_vault_pk: &Pubkey,
    msrm_vault_pk: &Pubkey,
    fees_vault_pk: &Pubkey,
    mango_cache_ai: &Pubkey,
    dex_program_pk: &Pubkey,
    signer_nonce: u64,
    valid_interval: u64,
    quote_optimal_util: I80F48,
    quote_optimal_rate: I80F48,
    quote_max_rate: I80F48,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(*admin_pk, true),
        AccountMeta::new_readonly(*quote_mint_pk, false),
        AccountMeta::new_readonly(*quote_vault_pk, false),
        AccountMeta::new(*quote_node_bank_pk, false),
        AccountMeta::new(*quote_root_bank_pk, false),
        AccountMeta::new_readonly(*insurance_vault_pk, false),
        AccountMeta::new_readonly(*msrm_vault_pk, false),
        AccountMeta::new_readonly(*fees_vault_pk, false),
        AccountMeta::new(*mango_cache_ai, false),
        AccountMeta::new_readonly(*dex_program_pk, false),
    ];
    let instr = MangoInstruction::InitMangoGroup {
        signer_nonce,
        valid_interval,
        quote_optimal_util,
        quote_optimal_rate,
        quote_max_rate,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn init_mango_account(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
    ];
    let instr = MangoInstruction::InitMangoAccount;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn close_mango_account(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new(*owner_pk, true),
    ];
    let instr = MangoInstruction::CloseMangoAccount;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn create_mango_account(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    system_prog_pk: &Pubkey,
    payer_pk: &Pubkey,
    account_num: u64,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*system_prog_pk, false),
        AccountMeta::new(*payer_pk, true),
    ];
    let instr = MangoInstruction::CreateMangoAccount { account_num };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn set_delegate(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    delegate_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*delegate_pk, false),
    ];
    let instr = MangoInstruction::SetDelegate {};
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn upgrade_mango_account_v0_v1(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
    ];
    let instr = MangoInstruction::UpgradeMangoAccountV0V1;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn deposit(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    vault_pk: &Pubkey,
    owner_token_account_pk: &Pubkey,
    quantity: u64,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new(*mango_cache_pk, false),
        AccountMeta::new(*root_bank_pk, false),
        AccountMeta::new(*node_bank_pk, false),
        AccountMeta::new(*vault_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
        AccountMeta::new(*owner_token_account_pk, false),
    ];
    let instr = MangoInstruction::Deposit { quantity };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn add_spot_market(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    oracle_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    dex_program_pk: &Pubkey,
    token_mint_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    vault_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    admin_pk: &Pubkey,
    maint_leverage: I80F48,
    init_leverage: I80F48,
    liquidation_fee: I80F48,
    optimal_util: I80F48,
    optimal_rate: I80F48,
    max_rate: I80F48,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new_readonly(*oracle_pk, false),
        AccountMeta::new_readonly(*spot_market_pk, false),
        AccountMeta::new_readonly(*dex_program_pk, false),
        AccountMeta::new_readonly(*token_mint_pk, false),
        AccountMeta::new(*node_bank_pk, false),
        AccountMeta::new_readonly(*vault_pk, false),
        AccountMeta::new(*root_bank_pk, false),
        AccountMeta::new_readonly(*admin_pk, true),
    ];
    let instr = MangoInstruction::AddSpotMarket {
        maint_leverage,
        init_leverage,
        liquidation_fee,
        optimal_util,
        optimal_rate,
        max_rate,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn create_perp_market(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    oracle_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    event_queue_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    mngo_mint_pk: &Pubkey,
    mngo_vault_pk: &Pubkey,
    admin_pk: &Pubkey,
    signer_pk: &Pubkey,
    maint_leverage: I80F48,
    init_leverage: I80F48,
    liquidation_fee: I80F48,
    maker_fee: I80F48,
    taker_fee: I80F48,
    base_lot_size: i64,
    quote_lot_size: i64,
    rate: I80F48,
    max_depth_bps: I80F48,
    target_period_length: u64,
    mngo_per_period: u64,
    exp: u8,
    version: u8,
    lm_size_shift: u8,
    base_decimals: u8,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new_readonly(*oracle_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*event_queue_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new_readonly(*mngo_mint_pk, false),
        AccountMeta::new(*mngo_vault_pk, false),
        AccountMeta::new_readonly(*admin_pk, true),
        AccountMeta::new(*signer_pk, false),
        AccountMeta::new_readonly(solana_program::system_program::ID, false),
        AccountMeta::new_readonly(spl_token::ID, false),
        AccountMeta::new_readonly(solana_program::sysvar::rent::ID, false),
    ];
    let instr = MangoInstruction::CreatePerpMarket {
        maint_leverage,
        init_leverage,
        liquidation_fee,
        maker_fee,
        taker_fee,
        base_lot_size,
        quote_lot_size,
        rate,
        max_depth_bps,
        target_period_length,
        mngo_per_period,
        exp,
        version,
        lm_size_shift,
        base_decimals,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn place_perp_order(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    event_queue_pk: &Pubkey,
    referrer_mango_account_pk: Option<&Pubkey>,
    open_orders_pks: &[Pubkey; MAX_PAIRS],
    side: Side,
    price: i64,
    quantity: i64,
    client_order_id: u64,
    order_type: OrderType,
    reduce_only: bool,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*event_queue_pk, false),
    ];
    accounts.extend(open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    if let Some(referrer_mango_account_pk) = referrer_mango_account_pk {
        accounts.push(AccountMeta::new(*referrer_mango_account_pk, false));
    }
    let instr = MangoInstruction::PlacePerpOrder {
        side,
        price,
        quantity,
        client_order_id,
        order_type,
        reduce_only,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn place_perp_order2(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    event_queue_pk: &Pubkey,
    referrer_mango_account_pk: Option<&Pubkey>,
    open_orders_pks: &[Pubkey],
    side: Side,
    price: i64,
    max_base_quantity: i64,
    max_quote_quantity: i64,
    client_order_id: u64,
    order_type: OrderType,
    reduce_only: bool,
    expiry_timestamp: Option<u64>,
    limit: u8,
    expiry_type: ExpiryType,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*event_queue_pk, false),
        AccountMeta::new(*referrer_mango_account_pk.unwrap_or(mango_account_pk), false),
    ];
    accounts.extend(open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::PlacePerpOrder2 {
        side,
        price,
        max_base_quantity,
        max_quote_quantity,
        client_order_id,
        order_type,
        reduce_only,
        expiry_timestamp: expiry_timestamp.unwrap_or(0),
        limit,
        expiry_type,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cancel_perp_order_by_client_id(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    client_order_id: u64,
    invalid_id_ok: bool,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
    ];
    let instr = MangoInstruction::CancelPerpOrderByClientId { client_order_id, invalid_id_ok };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cancel_perp_order(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    order_id: i128,
    invalid_id_ok: bool,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
    ];
    let instr = MangoInstruction::CancelPerpOrder { order_id, invalid_id_ok };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cancel_all_perp_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    limit: u8,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
    ];
    let instr = MangoInstruction::CancelAllPerpOrders { limit };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cancel_perp_orders_side(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    side: Side,
    limit: u8,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
    ];
    let instr = MangoInstruction::CancelPerpOrdersSide { side, limit };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn force_cancel_perp_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    liqee_mango_account_pk: &Pubkey,
    open_orders_pks: &[Pubkey],
    limit: u8,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*liqee_mango_account_pk, false),
    ];
    accounts.extend(open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::ForceCancelPerpOrders { limit };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cancel_all_spot_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    base_root_bank_pk: &Pubkey,
    base_node_bank_pk: &Pubkey,
    base_vault_pk: &Pubkey,
    quote_root_bank_pk: &Pubkey,
    quote_node_bank_pk: &Pubkey,
    quote_vault_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    open_orders_pk: &Pubkey,
    signer_pk: &Pubkey,
    dex_event_queue_pk: &Pubkey,
    dex_base_pk: &Pubkey,
    dex_quote_pk: &Pubkey,
    dex_signer_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    limit: u8,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*base_root_bank_pk, false),
        AccountMeta::new(*base_node_bank_pk, false),
        AccountMeta::new(*base_vault_pk, false),
        AccountMeta::new_readonly(*quote_root_bank_pk, false),
        AccountMeta::new(*quote_node_bank_pk, false),
        AccountMeta::new(*quote_vault_pk, false),
        AccountMeta::new(*spot_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*open_orders_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new(*dex_event_queue_pk, false),
        AccountMeta::new(*dex_base_pk, false),
        AccountMeta::new(*dex_quote_pk, false),
        AccountMeta::new_readonly(*dex_signer_pk, false),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
    ];
    let instr = MangoInstruction::CancelAllSpotOrders { limit };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn init_advanced_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    advanced_orders_pk: &Pubkey,
    system_prog_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new(*owner_pk, true),
        AccountMeta::new(*advanced_orders_pk, false),
        AccountMeta::new_readonly(*system_prog_pk, false),
    ];
    let instr = MangoInstruction::InitAdvancedOrders {};
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn close_advanced_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    advanced_orders_pk: &Pubkey,
    owner_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new(*owner_pk, true),
        AccountMeta::new(*advanced_orders_pk, false),
    ];
    let instr = MangoInstruction::CloseAdvancedOrders;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn add_perp_trigger_order(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    advanced_orders_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    system_prog_pk: &Pubkey,
    order_type: OrderType,
    side: Side,
    trigger_condition: TriggerCondition,
    reduce_only: bool,
    client_order_id: u64,
    price: i64,
    quantity: i64,
    trigger_price: I80F48,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_account_pk, false),
        AccountMeta::new(*owner_pk, true),
        AccountMeta::new(*advanced_orders_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*perp_market_pk, false),
        AccountMeta::new_readonly(*system_prog_pk, false),
    ];
    let instr = MangoInstruction::AddPerpTriggerOrder {
        order_type,
        side,
        trigger_condition,
        reduce_only,
        client_order_id,
        price,
        quantity,
        trigger_price,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn remove_advanced_order(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    advanced_orders_pk: &Pubkey,
    system_prog_pk: &Pubkey,
    order_index: u8,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_account_pk, false),
        AccountMeta::new(*owner_pk, true),
        AccountMeta::new(*advanced_orders_pk, false),
        AccountMeta::new_readonly(*system_prog_pk, false),
    ];
    let instr = MangoInstruction::RemoveAdvancedOrder { order_index };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn execute_perp_trigger_order(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    advanced_orders_pk: &Pubkey,
    agent_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    event_queue_pk: &Pubkey,
    order_index: u8,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new(*advanced_orders_pk, false),
        AccountMeta::new(*agent_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*event_queue_pk, false),
    ];
    let instr = MangoInstruction::ExecutePerpTriggerOrder { order_index };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn consume_events(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    event_queue_pk: &Pubkey,
    mango_acc_pks: &mut [Pubkey],
    limit: usize,
) -> Result<Instruction, ProgramError> {
    let fixed_accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*event_queue_pk, false),
    ];
    mango_acc_pks.sort();
    let mango_accounts = mango_acc_pks.into_iter().map(|pk| AccountMeta::new(*pk, false));
    let accounts = fixed_accounts.into_iter().chain(mango_accounts).collect();
    let instr = MangoInstruction::ConsumeEvents { limit };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn settle_pnl(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_a_pk: &Pubkey,
    mango_account_b_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    market_index: usize,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_a_pk, false),
        AccountMeta::new(*mango_account_b_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*root_bank_pk, false),
        AccountMeta::new(*node_bank_pk, false),
    ];
    let instr = MangoInstruction::SettlePnl { market_index };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn update_funding(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_cache_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new_readonly(*bids_pk, false),
        AccountMeta::new_readonly(*asks_pk, false),
    ];
    let instr = MangoInstruction::UpdateFunding {};
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn withdraw(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    vault_pk: &Pubkey,
    token_account_pk: &Pubkey,
    signer_pk: &Pubkey,
    open_orders_pks: &[Pubkey],
    quantity: u64,
    allow_borrow: bool,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*root_bank_pk, false),
        AccountMeta::new(*node_bank_pk, false),
        AccountMeta::new(*vault_pk, false),
        AccountMeta::new(*token_account_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
    ];
    accounts.extend(open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::Withdraw { quantity, allow_borrow };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn withdraw2(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    vault_pk: &Pubkey,
    token_account_pk: &Pubkey,
    signer_pk: &Pubkey,
    open_orders_pks: &mut dyn Iterator<Item = Pubkey>,
    quantity: u64,
    allow_borrow: bool,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*root_bank_pk, false),
        AccountMeta::new(*node_bank_pk, false),
        AccountMeta::new(*vault_pk, false),
        AccountMeta::new(*token_account_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
    ];
    accounts.extend(open_orders_pks.map(|pk| AccountMeta::new_readonly(pk, false)));
    let instr = MangoInstruction::Withdraw2 { quantity, allow_borrow };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn borrow(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    owner_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    open_orders_pks: &[Pubkey],
    quantity: u64,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*root_bank_pk, false),
        AccountMeta::new(*node_bank_pk, false),
    ];
    accounts.extend(open_orders_pks.iter().map(|pk| AccountMeta::new(*pk, false)));
    let instr = MangoInstruction::Borrow { quantity };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cache_prices(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    oracle_pks: &[Pubkey],
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_cache_pk, false),
    ];
    accounts.extend(oracle_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::CachePrices;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cache_root_banks(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    root_bank_pks: &[Pubkey],
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_cache_pk, false),
    ];
    accounts.extend(root_bank_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::CacheRootBanks;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn cache_perp_markets(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pks: &[Pubkey],
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_cache_pk, false),
    ];
    accounts.extend(perp_market_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::CachePerpMarkets;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn init_spot_open_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    open_orders_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    signer_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new(*open_orders_pk, false),
        AccountMeta::new_readonly(*spot_market_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(solana_program::sysvar::rent::ID, false),
    ];
    let instr = MangoInstruction::InitSpotOpenOrders;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn create_spot_open_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    open_orders_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    signer_pk: &Pubkey,
    payer_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new(*open_orders_pk, false),
        AccountMeta::new_readonly(*spot_market_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(solana_program::system_program::ID, false),
        AccountMeta::new(*payer_pk, true),
    ];
    let instr = MangoInstruction::CreateSpotOpenOrders;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn close_spot_open_orders(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    open_orders_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    signer_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new(*owner_pk, true),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new(*open_orders_pk, false),
        AccountMeta::new_readonly(*spot_market_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
    ];
    let instr = MangoInstruction::CloseSpotOpenOrders;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn place_spot_order(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    dex_request_queue_pk: &Pubkey,
    dex_event_queue_pk: &Pubkey,
    dex_base_pk: &Pubkey,
    dex_quote_pk: &Pubkey,
    base_root_bank_pk: &Pubkey,
    base_node_bank_pk: &Pubkey,
    base_vault_pk: &Pubkey,
    quote_root_bank_pk: &Pubkey,
    quote_node_bank_pk: &Pubkey,
    quote_vault_pk: &Pubkey,
    signer_pk: &Pubkey,
    dex_signer_pk: &Pubkey,
    msrm_or_srm_vault_pk: &Pubkey,
    open_orders_pks: &[Pubkey],
    market_index: usize,
    order: serum_dex::instruction::NewOrderInstructionV3,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new(*spot_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*dex_request_queue_pk, false),
        AccountMeta::new(*dex_event_queue_pk, false),
        AccountMeta::new(*dex_base_pk, false),
        AccountMeta::new(*dex_quote_pk, false),
        AccountMeta::new_readonly(*base_root_bank_pk, false),
        AccountMeta::new(*base_node_bank_pk, false),
        AccountMeta::new(*base_vault_pk, false),
        AccountMeta::new_readonly(*quote_root_bank_pk, false),
        AccountMeta::new(*quote_node_bank_pk, false),
        AccountMeta::new(*quote_vault_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(solana_program::sysvar::rent::ID, false),
        AccountMeta::new_readonly(*dex_signer_pk, false),
        AccountMeta::new_readonly(*msrm_or_srm_vault_pk, false),
    ];
    accounts.extend(open_orders_pks.iter().enumerate().map(|(i, pk)| {
        if i == market_index {
            AccountMeta::new(*pk, false)
        } else {
            AccountMeta::new_readonly(*pk, false)
        }
    }));
    let instr = MangoInstruction::PlaceSpotOrder { order };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn place_spot_order2(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    bids_pk: &Pubkey,
    asks_pk: &Pubkey,
    dex_request_queue_pk: &Pubkey,
    dex_event_queue_pk: &Pubkey,
    dex_base_pk: &Pubkey,
    dex_quote_pk: &Pubkey,
    base_root_bank_pk: &Pubkey,
    base_node_bank_pk: &Pubkey,
    base_vault_pk: &Pubkey,
    quote_root_bank_pk: &Pubkey,
    quote_node_bank_pk: &Pubkey,
    quote_vault_pk: &Pubkey,
    signer_pk: &Pubkey,
    dex_signer_pk: &Pubkey,
    msrm_or_srm_vault_pk: &Pubkey,
    open_orders_pks: &[Pubkey],
    affected_market_open_orders_index: usize,
    order: serum_dex::instruction::NewOrderInstructionV3,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new(*spot_market_pk, false),
        AccountMeta::new(*bids_pk, false),
        AccountMeta::new(*asks_pk, false),
        AccountMeta::new(*dex_request_queue_pk, false),
        AccountMeta::new(*dex_event_queue_pk, false),
        AccountMeta::new(*dex_base_pk, false),
        AccountMeta::new(*dex_quote_pk, false),
        AccountMeta::new_readonly(*base_root_bank_pk, false),
        AccountMeta::new(*base_node_bank_pk, false),
        AccountMeta::new(*base_vault_pk, false),
        AccountMeta::new_readonly(*quote_root_bank_pk, false),
        AccountMeta::new(*quote_node_bank_pk, false),
        AccountMeta::new(*quote_vault_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(*dex_signer_pk, false),
        AccountMeta::new_readonly(*msrm_or_srm_vault_pk, false),
    ];
    accounts.extend(open_orders_pks.iter().enumerate().map(|(i, pk)| {
        if i == affected_market_open_orders_index {
            AccountMeta::new(*pk, false)
        } else {
            AccountMeta::new_readonly(*pk, false)
        }
    }));
    let instr = MangoInstruction::PlaceSpotOrder2 { order };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn settle_funds(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    owner_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    dex_prog_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    open_orders_pk: &Pubkey,
    signer_pk: &Pubkey,
    dex_base_pk: &Pubkey,
    dex_quote_pk: &Pubkey,
    base_root_bank_pk: &Pubkey,
    base_node_bank_pk: &Pubkey,
    quote_root_bank_pk: &Pubkey,
    quote_node_bank_pk: &Pubkey,
    base_vault_pk: &Pubkey,
    quote_vault_pk: &Pubkey,
    dex_signer_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new_readonly(*owner_pk, true),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new_readonly(*dex_prog_pk, false),
        AccountMeta::new(*spot_market_pk, false),
        AccountMeta::new(*open_orders_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new(*dex_base_pk, false),
        AccountMeta::new(*dex_quote_pk, false),
        AccountMeta::new_readonly(*base_root_bank_pk, false),
        AccountMeta::new(*base_node_bank_pk, false),
        AccountMeta::new_readonly(*quote_root_bank_pk, false),
        AccountMeta::new(*quote_node_bank_pk, false),
        AccountMeta::new(*base_vault_pk, false),
        AccountMeta::new(*quote_vault_pk, false),
        AccountMeta::new_readonly(*dex_signer_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
    ];
    let instr = MangoInstruction::SettleFunds;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn add_oracle(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    oracle_pk: &Pubkey,
    admin_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new(*oracle_pk, false),
        AccountMeta::new_readonly(*admin_pk, true),
    ];
    let instr = MangoInstruction::AddOracle;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn update_root_bank(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pks: &[Pubkey],
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_cache_pk, false),
        AccountMeta::new(*root_bank_pk, false),
    ];
    accounts.extend(node_bank_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::UpdateRootBank;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn set_oracle(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    oracle_pk: &Pubkey,
    admin_pk: &Pubkey,
    price: I80F48,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*oracle_pk, false),
        AccountMeta::new_readonly(*admin_pk, true),
    ];
    let instr = MangoInstruction::SetOracle { price };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn liquidate_token_and_token(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    liqee_mango_account_pk: &Pubkey,
    liqor_mango_account_pk: &Pubkey,
    liqor_pk: &Pubkey,
    asset_root_bank_pk: &Pubkey,
    asset_node_bank_pk: &Pubkey,
    liab_root_bank_pk: &Pubkey,
    liab_node_bank_pk: &Pubkey,
    liqee_open_orders_pks: &[Pubkey],
    liqor_open_orders_pks: &[Pubkey],
    max_liab_transfer: I80F48,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*liqee_mango_account_pk, false),
        AccountMeta::new(*liqor_mango_account_pk, false),
        AccountMeta::new_readonly(*liqor_pk, true),
        AccountMeta::new_readonly(*asset_root_bank_pk, false),
        AccountMeta::new(*asset_node_bank_pk, false),
        AccountMeta::new_readonly(*liab_root_bank_pk, false),
        AccountMeta::new(*liab_node_bank_pk, false),
    ];
    accounts.extend(liqee_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    accounts.extend(liqor_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::LiquidateTokenAndToken { max_liab_transfer };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn liquidate_token_and_perp(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    liqee_mango_account_pk: &Pubkey,
    liqor_mango_account_pk: &Pubkey,
    liqor_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    node_bank_pk: &Pubkey,
    liqee_open_orders_pks: &[Pubkey],
    liqor_open_orders_pks: &[Pubkey],
    asset_type: AssetType,
    asset_index: usize,
    liab_type: AssetType,
    liab_index: usize,
    max_liab_transfer: I80F48,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*liqee_mango_account_pk, false),
        AccountMeta::new(*liqor_mango_account_pk, false),
        AccountMeta::new_readonly(*liqor_pk, true),
        AccountMeta::new_readonly(*root_bank_pk, false),
        AccountMeta::new(*node_bank_pk, false),
    ];
    accounts.extend(liqee_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    accounts.extend(liqor_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::LiquidateTokenAndPerp {
        asset_type,
        asset_index,
        liab_type,
        liab_index,
        max_liab_transfer,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn liquidate_perp_market(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    perp_market_pk: &Pubkey,
    event_queue_pk: &Pubkey,
    liqee_mango_account_pk: &Pubkey,
    liqor_mango_account_pk: &Pubkey,
    liqor_pk: &Pubkey,
    liqee_open_orders_pks: &[Pubkey],
    liqor_open_orders_pks: &[Pubkey],
    base_transfer_request: i64,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*perp_market_pk, false),
        AccountMeta::new(*event_queue_pk, false),
        AccountMeta::new(*liqee_mango_account_pk, false),
        AccountMeta::new(*liqor_mango_account_pk, false),
        AccountMeta::new_readonly(*liqor_pk, true),
    ];
    accounts.extend(liqee_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    accounts.extend(liqor_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::LiquidatePerpMarket { base_transfer_request };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn change_spot_market_params(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    spot_market_pk: &Pubkey,
    root_bank_pk: &Pubkey,
    admin_pk: &Pubkey,
    maint_leverage: Option<I80F48>,
    init_leverage: Option<I80F48>,
    liquidation_fee: Option<I80F48>,
    optimal_util: Option<I80F48>,
    optimal_rate: Option<I80F48>,
    max_rate: Option<I80F48>,
    version: Option<u8>,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new(*mango_group_pk, false),
        AccountMeta::new(*spot_market_pk, false),
        AccountMeta::new(*root_bank_pk, false),
        AccountMeta::new_readonly(*admin_pk, true),
    ];
    let instr = MangoInstruction::ChangeSpotMarketParams {
        maint_leverage,
        init_leverage,
        liquidation_fee,
        optimal_util,
        optimal_rate,
        max_rate,
        version,
    };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn set_market_mode(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    admin_pk: &Pubkey,
    market_index: usize,
    mode: MarketMode,
    market_type: AssetType,
) -> Result<Instruction, ProgramError> {
    let accounts =
        vec![AccountMeta::new(*mango_group_pk, false), AccountMeta::new_readonly(*admin_pk, true)];
    let instr = MangoInstruction::SetMarketMode { market_index, mode, market_type };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn liquidate_delisting_token(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_cache_pk: &Pubkey,
    dust_account_pk: &Pubkey,
    liqee_mango_account_pk: &Pubkey,
    liqor_mango_account_pk: &Pubkey,
    liqor_pk: &Pubkey,
    asset_root_bank_pk: &Pubkey,
    asset_node_bank_pk: &Pubkey,
    liab_root_bank_pk: &Pubkey,
    liab_node_bank_pk: &Pubkey,
    liab_vault_pk: &Pubkey,
    liqee_liab_token_account_pk: &Pubkey,
    liqor_liab_token_account_pk: &Pubkey,
    liqee_open_orders_pks: &[Pubkey],
    liqor_open_orders_pks: &[Pubkey],
    signer_pk: &Pubkey,
    max_liquidate_amount: u64,
) -> Result<Instruction, ProgramError> {
    let mut accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new_readonly(*mango_cache_pk, false),
        AccountMeta::new(*dust_account_pk, false),
        AccountMeta::new(*liqee_mango_account_pk, false),
        AccountMeta::new(*liqor_mango_account_pk, false),
        AccountMeta::new_readonly(*liqor_pk, true),
        AccountMeta::new_readonly(*asset_root_bank_pk, false),
        AccountMeta::new(*asset_node_bank_pk, false),
        AccountMeta::new_readonly(*liab_root_bank_pk, false),
        AccountMeta::new(*liab_node_bank_pk, false),
        AccountMeta::new(*liab_vault_pk, false),
        AccountMeta::new(*liqee_liab_token_account_pk, false),
        AccountMeta::new(*liqor_liab_token_account_pk, false),
        AccountMeta::new_readonly(*signer_pk, false),
        AccountMeta::new_readonly(spl_token::ID, false),
    ];
    accounts.extend(liqee_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    accounts.extend(liqor_open_orders_pks.iter().map(|pk| AccountMeta::new_readonly(*pk, false)));
    let instr = MangoInstruction::LiquidateDelistingToken { max_liquidate_amount };
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
pub fn create_dust_account(
    program_id: &Pubkey,
    mango_group_pk: &Pubkey,
    mango_account_pk: &Pubkey,
    payer_pk: &Pubkey,
) -> Result<Instruction, ProgramError> {
    let accounts = vec![
        AccountMeta::new_readonly(*mango_group_pk, false),
        AccountMeta::new(*mango_account_pk, false),
        AccountMeta::new(*payer_pk, true),
        AccountMeta::new_readonly(solana_program::system_program::ID, false),
    ];
    let instr = MangoInstruction::CreateDustAccount;
    let data = instr.pack();
    Ok(Instruction { program_id: *program_id, accounts, data })
}
fn serialize_option_fixed_width<S: serde::Serializer, T: Sized + Default + Serialize>(
    opt: &Option<T>,
    serializer: S,
) -> Result<S::Ok, S::Error> {
    use serde::ser::SerializeTuple;
    let mut tup = serializer.serialize_tuple(2)?;
    match opt {
        Some(value) => {
            tup.serialize_element(&true)?;
            tup.serialize_element(&value)?;
        }
        None => {
            tup.serialize_element(&false)?;
            tup.serialize_element(&T::default())?;
        }
    };
    tup.end()
}