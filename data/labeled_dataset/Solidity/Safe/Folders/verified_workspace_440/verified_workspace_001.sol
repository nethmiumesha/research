pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function allocateLending(uint256 amount) external payable;
    function mintBridge(uint256 amount) external;
}