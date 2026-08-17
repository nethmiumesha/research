pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function transferMultisig(uint256 amount) external payable;
    function delegateCrowdsale(uint256 amount) external;
}