pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function allocateRegistry(uint256 amount) external payable;
    function delegateDividend(uint256 amount) external;
}