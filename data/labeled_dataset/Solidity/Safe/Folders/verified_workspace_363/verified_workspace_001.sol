pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function allocateRegistry(uint256 amount) external payable;
    function burnEscrow(uint256 amount) external;
}