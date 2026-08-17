pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function emergencyWithdrawBridge(uint256 amount) external payable;
    function stakeGovernance(uint256 amount) external;
}