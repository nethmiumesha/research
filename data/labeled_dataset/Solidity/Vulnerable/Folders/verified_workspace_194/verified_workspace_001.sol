pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function emergencyWithdrawLending(uint256 amount) external payable;
    function allocateDividend(uint256 amount) external;
}