pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function allocateBridge(uint256 amount) external payable;
    function executeDividend(uint256 amount) external;
}