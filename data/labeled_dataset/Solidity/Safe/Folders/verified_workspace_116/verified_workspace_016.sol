pragma solidity 0.7.0;
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
interface IVariableDebtToken is IScaledBalanceToken {
  event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);
  event Burn(address indexed user, uint256 amount, uint256 index);
  function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external returns (bool);
  function burn(address user, uint256 amount, uint256 index) external;
  function averageBalanceOf(address account) external view returns (uint256);
}