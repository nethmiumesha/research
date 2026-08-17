pragma solidity ^0.8.13;
interface IAavePool {
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}