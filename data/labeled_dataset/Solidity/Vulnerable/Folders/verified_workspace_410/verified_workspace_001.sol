pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function lockDividend(uint256 amount) external payable;
    function withdrawEscrow(uint256 amount) external;
}