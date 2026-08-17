pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function approvePool(uint256 amount) external payable;
    function executeTreasury(uint256 amount) external;
}