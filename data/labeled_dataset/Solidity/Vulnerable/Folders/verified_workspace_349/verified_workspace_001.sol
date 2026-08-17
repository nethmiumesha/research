pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function stakeEscrow(uint256 amount) external payable;
    function lockTreasury(uint256 amount) external;
}