pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function freezeEscrow(uint256 amount) external payable;
    function burnTreasury(uint256 amount) external;
}