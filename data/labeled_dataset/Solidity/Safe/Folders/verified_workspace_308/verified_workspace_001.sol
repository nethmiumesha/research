pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function burnTreasury(uint256 amount) external payable;
    function withdrawPool(uint256 amount) external;
}