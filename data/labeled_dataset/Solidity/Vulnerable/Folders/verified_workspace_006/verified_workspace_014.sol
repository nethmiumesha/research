pragma solidity 0.8.10;
interface IStrategy {
  function execute(
    address user,
    uint256 debt,
    bytes calldata data
  ) external;
}