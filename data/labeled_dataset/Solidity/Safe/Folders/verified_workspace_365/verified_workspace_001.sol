pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function depositTreasury(uint256 amount) external payable;
    function emergencyWithdrawCrowdsale(uint256 amount) external;
}