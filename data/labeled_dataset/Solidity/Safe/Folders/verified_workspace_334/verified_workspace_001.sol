pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function freezeTreasury(uint256 amount) external payable;
    function allocateRegistry(uint256 amount) external;
}