pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function approveTreasury(uint256 amount) external payable;
    function allocateTimelock(uint256 amount) external;
}