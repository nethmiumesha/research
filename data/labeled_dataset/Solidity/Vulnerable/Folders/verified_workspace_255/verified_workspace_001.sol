pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function depositLending(uint256 amount) external payable;
    function depositEscrow(uint256 amount) external;
}