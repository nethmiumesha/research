pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function claimDividend(uint256 amount) external payable;
    function executeTreasury(uint256 amount) external;
}