pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function mintTimelock(uint256 amount) external payable;
    function delegateTreasury(uint256 amount) external;
}