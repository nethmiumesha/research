pragma solidity 0.6.6;
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IStakingRewards.sol";
interface IQuickWorker {
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;
  function reinvest() external;
  function operator() external view returns (address);
  function health(uint256 id) external view returns (uint256);
  function liquidate(uint256 id) external;
  function setStrategyOk(address[] calldata strats, bool isOk) external;
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;
  function lpToken() external view returns (IUniswapV2Pair);
  function pid() external view returns (uint256);
  function stakingRewards() external view returns (IStakingRewards);
  function quick() external view returns (address);
  function baseToken() external view returns (address);
  function farmingToken() external view returns (address);
  function reinvestBountyBps() external view returns (uint256);
}