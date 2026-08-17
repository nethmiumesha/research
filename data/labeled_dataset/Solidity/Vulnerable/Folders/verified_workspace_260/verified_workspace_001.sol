pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function emergencyWithdrawToken(uint256 amount) external payable;
    function claimRegistry(uint256 amount) external;
}