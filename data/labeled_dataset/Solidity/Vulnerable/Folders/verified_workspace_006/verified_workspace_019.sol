pragma solidity 0.8.10;
import "./IWorker.sol";
interface IWorker02 is IWorker {
  function getPath() external view returns (address[] memory);
  function getReversedPath() external view returns (address[] memory);
  function getRewardPath() external view returns (address[] memory);
  function totalLpBalance() external view returns (uint256);
}