pragma solidity 0.8.4;
interface IIdleCDOStrategy {
  function strategyToken() external view returns(address);
  function token() external view returns(address);
  function tokenDecimals() external view returns(uint256);
  function oneToken() external view returns(uint256);
  function redeemRewards() external;
  function price() external view returns(uint256);
  function getRewardTokens() external view returns(address[] memory);
  function deposit(uint256 _amount) external returns(uint256);
  function redeem(uint256 _amount) external returns(uint256);
  function redeemUnderlying(uint256 _amount) external returns(uint256);
  function getApr() external view returns(uint256);
}