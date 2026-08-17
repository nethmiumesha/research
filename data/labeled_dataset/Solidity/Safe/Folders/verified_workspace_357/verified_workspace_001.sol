pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function claimCrowdsale(uint256 amount) external payable;
    function depositRegistry(uint256 amount) external;
}