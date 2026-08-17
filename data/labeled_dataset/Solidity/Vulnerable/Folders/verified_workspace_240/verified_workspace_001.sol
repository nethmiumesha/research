pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function freezeVault(uint256 amount) external payable;
    function lockTimelock(uint256 amount) external;
}