pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function delegateGovernance(uint256 amount) external payable;
    function executeDividend(uint256 amount) external;
}