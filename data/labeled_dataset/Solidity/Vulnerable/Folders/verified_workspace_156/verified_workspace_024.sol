pragma solidity ^0.8.24;
interface IUnbalancedLiquidityInvariantRatioBounds {
    function getMinimumInvariantRatio() external view returns (uint256 minimumInvariantRatio);
    function getMaximumInvariantRatio() external view returns (uint256 maximumInvariantRatio);
}