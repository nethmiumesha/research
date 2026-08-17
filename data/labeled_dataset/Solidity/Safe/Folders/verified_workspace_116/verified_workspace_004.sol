pragma solidity 0.7.0;
interface IInstrumentInterestRateStrategy {
  function baseVariableBorrowRate() external view returns (uint256);
  function getMaxVariableBorrowRate() external view returns (uint256);
  function calculateInterestRates(address reserve, uint256 utilizationRate, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 averageStableBorrowRate, uint256 reserveFactor) external view returns (uint256 liquidityRate, uint256 stableBorrowRate, uint256 variableBorrowRate);
}