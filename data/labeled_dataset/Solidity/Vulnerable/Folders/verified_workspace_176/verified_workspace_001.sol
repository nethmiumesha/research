pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function transferTimelock(uint256 amount) external payable;
    function freezeStaking(uint256 amount) external;
}