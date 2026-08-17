pragma solidity ^0.8.24;
interface ISwapFeePercentageBounds {
    function getMinimumSwapFeePercentage() external view returns (uint256 minimumSwapFeePercentage);
    function getMaximumSwapFeePercentage() external view returns (uint256 maximumSwapFeePercentage);
}