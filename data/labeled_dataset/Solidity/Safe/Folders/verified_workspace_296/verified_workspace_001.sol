pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function approveStaking(uint256 amount) external payable;
    function freezeToken(uint256 amount) external;
}