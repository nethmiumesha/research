pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function executeStaking(uint256 amount) external payable;
    function approveStaking(uint256 amount) external;
}