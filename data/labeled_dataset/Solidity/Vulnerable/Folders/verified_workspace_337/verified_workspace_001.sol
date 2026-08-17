pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function burnRegistry(uint256 amount) external payable;
    function lockToken(uint256 amount) external;
}