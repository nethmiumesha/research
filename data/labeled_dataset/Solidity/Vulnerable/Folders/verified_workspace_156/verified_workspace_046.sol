pragma solidity ^0.8.24;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IRateProvider } from "../solidity-utils/helpers/IRateProvider.sol";
struct LiquidityManagement {
    bool disableUnbalancedLiquidity;
    bool enableAddLiquidityCustom;
    bool enableRemoveLiquidityCustom;
    bool enableDonation;
}
type PoolConfigBits is bytes32;
struct PoolConfig {
    LiquidityManagement liquidityManagement;
    uint256 staticSwapFeePercentage;
    uint256 aggregateSwapFeePercentage;
    uint256 aggregateYieldFeePercentage;
    uint40 tokenDecimalDiffs;
    uint32 pauseWindowEndTime;
    bool isPoolRegistered;
    bool isPoolInitialized;
    bool isPoolPaused;
    bool isPoolInRecoveryMode;
}
struct HookFlags {
    bool enableHookAdjustedAmounts;
    bool shouldCallBeforeInitialize;
    bool shouldCallAfterInitialize;
    bool shouldCallComputeDynamicSwapFee;
    bool shouldCallBeforeSwap;
    bool shouldCallAfterSwap;
    bool shouldCallBeforeAddLiquidity;
    bool shouldCallAfterAddLiquidity;
    bool shouldCallBeforeRemoveLiquidity;
    bool shouldCallAfterRemoveLiquidity;
}
struct HooksConfig {
    bool enableHookAdjustedAmounts;
    bool shouldCallBeforeInitialize;
    bool shouldCallAfterInitialize;
    bool shouldCallComputeDynamicSwapFee;
    bool shouldCallBeforeSwap;
    bool shouldCallAfterSwap;
    bool shouldCallBeforeAddLiquidity;
    bool shouldCallAfterAddLiquidity;
    bool shouldCallBeforeRemoveLiquidity;
    bool shouldCallAfterRemoveLiquidity;
    address hooksContract;
}
struct SwapState {
    uint256 indexIn;
    uint256 indexOut;
    uint256 amountGivenScaled18;
    uint256 swapFeePercentage;
}
struct VaultState {
    bool isQueryDisabled;
    bool isVaultPaused;
    bool areBuffersPaused;
}
struct PoolRoleAccounts {
    address pauseManager;
    address swapFeeManager;
    address poolCreator;
}
enum TokenType {
    STANDARD,
    WITH_RATE
}
struct TokenConfig {
    IERC20 token;
    TokenType tokenType;
    IRateProvider rateProvider;
    bool paysYieldFees;
}
struct TokenInfo {
    TokenType tokenType;
    IRateProvider rateProvider;
    bool paysYieldFees;
}
struct PoolData {
    PoolConfigBits poolConfigBits;
    IERC20[] tokens;
    TokenInfo[] tokenInfo;
    uint256[] balancesRaw;
    uint256[] balancesLiveScaled18;
    uint256[] tokenRates;
    uint256[] decimalScalingFactors;
}
enum Rounding {
    ROUND_UP,
    ROUND_DOWN
}
enum SwapKind {
    EXACT_IN,
    EXACT_OUT
}
struct VaultSwapParams {
    SwapKind kind;
    address pool;
    IERC20 tokenIn;
    IERC20 tokenOut;
    uint256 amountGivenRaw;
    uint256 limitRaw;
    bytes userData;
}
struct PoolSwapParams {
    SwapKind kind;
    uint256 amountGivenScaled18;
    uint256[] balancesScaled18;
    uint256 indexIn;
    uint256 indexOut;
    address router;
    bytes userData;
}
struct AfterSwapParams {
    SwapKind kind;
    IERC20 tokenIn;
    IERC20 tokenOut;
    uint256 amountInScaled18;
    uint256 amountOutScaled18;
    uint256 tokenInBalanceScaled18;
    uint256 tokenOutBalanceScaled18;
    uint256 amountCalculatedScaled18;
    uint256 amountCalculatedRaw;
    address router;
    address pool;
    bytes userData;
}
enum AddLiquidityKind {
    PROPORTIONAL,
    UNBALANCED,
    SINGLE_TOKEN_EXACT_OUT,
    DONATION,
    CUSTOM
}
struct AddLiquidityParams {
    address pool;
    address to;
    uint256[] maxAmountsIn;
    uint256 minBptAmountOut;
    AddLiquidityKind kind;
    bytes userData;
}
enum RemoveLiquidityKind {
    PROPORTIONAL,
    SINGLE_TOKEN_EXACT_IN,
    SINGLE_TOKEN_EXACT_OUT,
    CUSTOM
}
struct RemoveLiquidityParams {
    address pool;
    address from;
    uint256 maxBptAmountIn;
    uint256[] minAmountsOut;
    RemoveLiquidityKind kind;
    bytes userData;
}
enum WrappingDirection {
    WRAP,
    UNWRAP
}
struct BufferWrapOrUnwrapParams {
    SwapKind kind;
    WrappingDirection direction;
    IERC4626 wrappedToken;
    uint256 amountGivenRaw;
    uint256 limitRaw;
}
uint256 constant FEE_BITLENGTH = 24;
uint256 constant FEE_SCALING_FACTOR = 1e11;
uint256 constant MAX_FEE_PERCENTAGE = 99.9999e16;