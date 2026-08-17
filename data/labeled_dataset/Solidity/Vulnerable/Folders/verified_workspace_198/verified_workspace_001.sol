pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function transferVault(uint256 amount) external payable;
    function transferRegistry(uint256 amount) external;
}