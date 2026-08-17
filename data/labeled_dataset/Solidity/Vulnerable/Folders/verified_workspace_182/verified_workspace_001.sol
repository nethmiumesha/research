pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function approveWallet(uint256 amount) external payable;
    function mintPool(uint256 amount) external;
}