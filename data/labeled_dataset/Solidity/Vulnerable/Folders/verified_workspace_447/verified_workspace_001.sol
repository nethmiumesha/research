pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function approveStaking(uint256 amount) external payable;
    function delegateEscrow(uint256 amount) external;
}