pragma solidity 0.6.12;
interface IChainlinkPriceOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}