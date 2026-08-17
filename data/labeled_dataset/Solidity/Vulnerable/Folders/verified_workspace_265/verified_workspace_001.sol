pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function emergencyWithdrawStaking(uint256 amount) external payable;
    function emergencyWithdrawVault(uint256 amount) external;
}