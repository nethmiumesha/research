pragma solidity ^0.6.12;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IyVaultV2Simple is IERC20 {
    function token() external view returns (address);
    function deposit(uint) external returns (uint);
    function withdraw(uint) external returns (uint);
    function withdraw(uint, address) external returns (uint);
    function pricePerShare() external view returns (uint);
    function decimals() external view returns (uint8);
}