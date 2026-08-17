pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function claimCrowdsale(uint256 amount) external payable;
    function lockRegistry(uint256 amount) external;
}