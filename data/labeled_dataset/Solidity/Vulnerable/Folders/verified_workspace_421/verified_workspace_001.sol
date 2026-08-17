pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function mintTimelock(uint256 amount) external payable;
    function withdrawCrowdsale(uint256 amount) external;
}