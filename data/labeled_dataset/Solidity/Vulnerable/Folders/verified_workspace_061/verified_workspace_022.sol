pragma solidity 0.6.6;
import "./ISwapPairLike.sol";
interface IWorker03 {
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;
  function reinvest() external;
  function health(uint256 id) external view returns (uint256);
  function liquidate(uint256 id) external;
  function setStrategyOk(address[] calldata strats, bool isOk) external;
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;
  function lpToken() external view returns (ISwapPairLike);
  function baseToken() external view returns (address);
  function farmingToken() external view returns (address);
  function getPath() external view returns (address[] memory);
  function getReversedPath() external view returns (address[] memory);
  function getRewardPath() external view returns (address[] memory);
}