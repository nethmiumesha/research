pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function withdrawRegistry(uint256 amount) external payable;
    function mintPool(uint256 amount) external;
}