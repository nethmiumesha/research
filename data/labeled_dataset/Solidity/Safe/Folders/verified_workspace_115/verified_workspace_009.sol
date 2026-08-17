pragma solidity 0.7.0;
interface ILendingRateOracle {
  function getMarketBorrowRate(address asset) external view returns (uint256);
  function setMarketBorrowRate(address asset, uint256 rate) external;
}