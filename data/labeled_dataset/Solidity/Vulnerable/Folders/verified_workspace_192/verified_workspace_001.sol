pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function emergencyWithdrawWallet(uint256 amount) external payable;
    function mintCrowdsale(uint256 amount) external;
}