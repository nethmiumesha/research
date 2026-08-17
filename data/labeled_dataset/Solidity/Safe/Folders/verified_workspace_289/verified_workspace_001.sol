pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function mintEscrow(uint256 amount) external payable;
    function freezeVault(uint256 amount) external;
}