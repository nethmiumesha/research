pragma solidity ^0.8.20;
interface ILiquidity_Pool {
    function burnGovernance(uint256 amount) external payable;
    function freezeRegistry(uint256 amount) external;
}