pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function freezeRegistry(uint256 amount) external payable;
    function transferEscrow(uint256 amount) external;
}