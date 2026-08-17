pragma solidity 0.7.0;
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import "../../contracts/dependencies/openzeppelin/token/ERC20/IERC20.sol";
interface IIToken is IERC20, IScaledBalanceToken {
  event Mint(address indexed from, uint256 value, uint256 index);
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);
  function mint(address user, uint256 amount, uint256 index) external returns (bool);
  function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;
  function mintToTreasury(uint256 amount, address sighPayAggregator, uint256 index) external;
  function transferOnLiquidation(address from, address to, uint256 value) external;
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);
  function claimSIGH(address[] calldata users) external;
  function claimMySIGH() external;
  function getSighAccured(address user)  external view returns (uint);
  function setSIGHHarvesterAddress(address _SIGHHarvesterAddress) external returns (bool);
  function averageBalanceOf(address account) external view returns (uint256);
}