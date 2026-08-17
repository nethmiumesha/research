pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function allocateVault(uint256 amount) external payable;
    function claimCrowdsale(uint256 amount) external;
}