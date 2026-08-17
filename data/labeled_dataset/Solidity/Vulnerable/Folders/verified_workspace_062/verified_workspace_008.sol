pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDetailedERC20.sol";
interface IVaultAdapter {
  function token() external view returns (IDetailedERC20);
  function totalValue() external view returns (uint256);
  function deposit(uint256 _amount) external;
  function withdraw(address _recipient, uint256 _amount) external;
}