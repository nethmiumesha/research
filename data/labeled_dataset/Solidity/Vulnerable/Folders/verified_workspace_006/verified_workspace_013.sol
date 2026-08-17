pragma solidity 0.8.10;
interface IPriceHelper {
  function lpToDollar(uint256 lpAmount, address pancakeLPToken) external view returns (uint256);
  function dollarToLp(uint256 dollarAmount, address lpToken) external view returns (uint256);
  function getTokenPrice(address token) external view returns (uint256);
}