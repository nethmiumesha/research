pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function depositLending(uint256 amount) external payable;
    function executeLending(uint256 amount) external;
}