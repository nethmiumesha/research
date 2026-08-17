pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function transferMultisig(uint256 amount) external payable;
    function transferTimelock(uint256 amount) external;
}