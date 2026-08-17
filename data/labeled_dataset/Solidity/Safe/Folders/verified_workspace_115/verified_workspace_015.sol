pragma solidity 0.7.0;
interface ITokenConfiguration {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
  function POOL() external view returns (address);
  function balanceOf(address user) external view returns (uint);
}