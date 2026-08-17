pragma solidity 0.6.6;
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import "../interfaces/IStrategy.sol";
import "../../utils/AlpacaMath.sol";
import "../../utils/SafeToken.sol";
contract MockWaultSwapWorker {
  using SafeToken for address;
  IPancakePair public lpToken;
  address public baseToken;
  address public farmingToken;
  constructor(
    IPancakePair _lpToken,
    address _baseToken,
    address _farmingToken
  ) public {
    lpToken = _lpToken;
    baseToken = _baseToken;
    farmingToken = _farmingToken;
  }
  function work(
    uint256,
    address user,
    uint256 debt,
    bytes calldata data
  ) external {
    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    baseToken.safeTransfer(strat, baseToken.myBalance());
    require(
      lpToken.transfer(strat, lpToken.balanceOf(address(this))),
      "WaultWorker::work:: unable to transfer lp to strat"
    );
    IStrategy(strat).execute(user, debt, ext);
    baseToken.safeTransfer(msg.sender, baseToken.myBalance());
  }
}