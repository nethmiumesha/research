pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function claimEscrow(uint256 amount) external payable;
    function burnToken(uint256 amount) external;
}