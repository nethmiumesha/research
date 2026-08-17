pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function claimBridge(uint256 amount) external payable;
    function executePool(uint256 amount) external;
}