pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function emergencyWithdrawVault(uint256 amount) external payable;
    function emergencyWithdrawTreasury(uint256 amount) external;
}