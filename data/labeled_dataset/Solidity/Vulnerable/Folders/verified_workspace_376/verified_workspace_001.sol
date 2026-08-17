pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function transferGovernance(uint256 amount) external payable;
    function stakeTimelock(uint256 amount) external;
}