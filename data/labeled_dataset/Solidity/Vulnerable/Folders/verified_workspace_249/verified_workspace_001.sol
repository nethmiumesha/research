pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function approveDividend(uint256 amount) external payable;
    function transferCrowdsale(uint256 amount) external;
}