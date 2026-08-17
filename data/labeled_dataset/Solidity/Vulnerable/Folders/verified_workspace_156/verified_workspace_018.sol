pragma solidity ^0.8.24;
import {
    TokenConfig,
    LiquidityManagement,
    PoolSwapParams,
    AfterSwapParams,
    HookFlags,
    AddLiquidityKind,
    RemoveLiquidityKind,
    SwapKind
} from "./VaultTypes.sol";
interface IHooks {
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory tokenConfig,
        LiquidityManagement calldata liquidityManagement
    ) external returns (bool success);
    function getHookFlags() external view returns (HookFlags memory hookFlags);
    function onBeforeInitialize(uint256[] memory exactAmountsIn, bytes memory userData) external returns (bool success);
    function onAfterInitialize(
        uint256[] memory exactAmountsIn,
        uint256 bptAmountOut,
        bytes memory userData
    ) external returns (bool success);
    function onBeforeAddLiquidity(
        address router,
        address pool,
        AddLiquidityKind kind,
        uint256[] memory maxAmountsInScaled18,
        uint256 minBptAmountOut,
        uint256[] memory balancesScaled18,
        bytes memory userData
    ) external returns (bool success);
    function onAfterAddLiquidity(
        address router,
        address pool,
        AddLiquidityKind kind,
        uint256[] memory amountsInScaled18,
        uint256[] memory amountsInRaw,
        uint256 bptAmountOut,
        uint256[] memory balancesScaled18,
        bytes memory userData
    ) external returns (bool success, uint256[] memory hookAdjustedAmountsInRaw);
    function onBeforeRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind kind,
        uint256 maxBptAmountIn,
        uint256[] memory minAmountsOutScaled18,
        uint256[] memory balancesScaled18,
        bytes memory userData
    ) external returns (bool success);
    function onAfterRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind kind,
        uint256 bptAmountIn,
        uint256[] memory amountsOutScaled18,
        uint256[] memory amountsOutRaw,
        uint256[] memory balancesScaled18,
        bytes memory userData
    ) external returns (bool success, uint256[] memory hookAdjustedAmountsOutRaw);
    function onBeforeSwap(PoolSwapParams calldata params, address pool) external returns (bool success);
    function onAfterSwap(
        AfterSwapParams calldata params
    ) external returns (bool success, uint256 hookAdjustedAmountCalculatedRaw);
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) external view returns (bool success, uint256 dynamicSwapFeePercentage);
}