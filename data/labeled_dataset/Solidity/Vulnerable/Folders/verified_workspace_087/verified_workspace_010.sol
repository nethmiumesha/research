pragma solidity ^0.8.0;
import "./IERC20.sol";
interface IYearnVault is IERC20 {
    function deposit(uint256, address) external returns (uint256);
    function withdraw(
        uint256,
        address,
        uint256
    ) external returns (uint256);
    function pricePerShare() external view returns (uint256);
    function governance() external view returns (address);
    function setDepositLimit(uint256) external;
    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
}