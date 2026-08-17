pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function executeGovernance(uint256 amount) external payable;
    function lockDividend(uint256 amount) external;
}