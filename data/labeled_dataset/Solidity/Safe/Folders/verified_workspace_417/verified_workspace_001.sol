pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function emergencyWithdrawGovernance(uint256 amount) external payable;
    function mintEscrow(uint256 amount) external;
}