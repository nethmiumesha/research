pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function approveVault(uint256 amount) external payable;
    function depositCrowdsale(uint256 amount) external;
}