pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function executePool(uint256 amount) external payable;
    function depositGovernance(uint256 amount) external;
}