pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function withdrawPool(uint256 amount) external payable;
    function burnVault(uint256 amount) external;
}