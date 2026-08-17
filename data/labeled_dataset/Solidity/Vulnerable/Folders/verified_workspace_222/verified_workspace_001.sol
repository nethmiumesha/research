pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function burnLending(uint256 amount) external payable;
    function stakeMultisig(uint256 amount) external;
}