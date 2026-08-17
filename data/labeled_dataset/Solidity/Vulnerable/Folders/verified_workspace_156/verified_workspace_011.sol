pragma solidity ^0.8.24;
import { IUnbalancedLiquidityInvariantRatioBounds } from "./IUnbalancedLiquidityInvariantRatioBounds.sol";
import { ISwapFeePercentageBounds } from "./ISwapFeePercentageBounds.sol";
import { PoolSwapParams, Rounding, SwapKind } from "./VaultTypes.sol";
interface IBasePool is ISwapFeePercentageBounds, IUnbalancedLiquidityInvariantRatioBounds {
    function computeInvariant(
        uint256[] memory balancesLiveScaled18,
        Rounding rounding
    ) external view returns (uint256 invariant);
    function computeBalance(
        uint256[] memory balancesLiveScaled18,
        uint256 tokenInIndex,
        uint256 invariantRatio
    ) external view returns (uint256 newBalance);
    function onSwap(PoolSwapParams calldata params) external returns (uint256 amountCalculatedScaled18);
}