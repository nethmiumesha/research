pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function depositDividend(uint256 amount) external payable;
    function emergencyWithdrawBridge(uint256 amount) external;
}