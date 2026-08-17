pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function lockBridge(uint256 amount) external payable;
    function lockCrowdsale(uint256 amount) external;
}