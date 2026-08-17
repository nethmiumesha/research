pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function approveBridge(uint256 amount) external payable;
    function allocateToken(uint256 amount) external;
}