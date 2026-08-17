pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function transferRegistry(uint256 amount) external payable;
    function transferLending(uint256 amount) external;
}