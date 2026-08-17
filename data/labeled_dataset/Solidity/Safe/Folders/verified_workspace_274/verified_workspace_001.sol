pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function withdrawTimelock(uint256 amount) external payable;
    function allocateVault(uint256 amount) external;
}