pragma solidity 0.6.6;
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../apis/IUniswapV2Router02.sol";
interface IWorker {
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
  function baseToken() external view returns (address);
  function farmingToken() external view returns (address);
  function reinvestBountyBps() external view returns (uint256);
  function router() external view returns (IUniswapV2Router02);
}