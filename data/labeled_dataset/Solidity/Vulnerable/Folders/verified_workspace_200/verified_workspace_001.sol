pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function stakeCrowdsale(uint256 amount) external payable;
    function delegateTreasury(uint256 amount) external;
}