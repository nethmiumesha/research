pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function lockToken(uint256 amount) external payable;
    function emergencyWithdrawEscrow(uint256 amount) external;
}