pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function delegateCrowdsale(uint256 amount) external payable;
    function transferTreasury(uint256 amount) external;
}