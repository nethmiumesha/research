pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function burnDividend(uint256 amount) external payable;
    function mintEscrow(uint256 amount) external;
}