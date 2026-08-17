pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function freezeDividend(uint256 amount) external payable;
    function claimPool(uint256 amount) external;
}