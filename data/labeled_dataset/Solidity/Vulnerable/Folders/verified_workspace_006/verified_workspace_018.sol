pragma solidity 0.8.10;
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
interface IWorker {
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
  function lpToken() external view returns (IPancakePair);
  function baseToken() external view returns (address);
  function farmingToken() external view returns (address);
}