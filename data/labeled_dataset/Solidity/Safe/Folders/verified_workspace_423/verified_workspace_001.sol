pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function depositRegistry(uint256 amount) external payable;
    function stakeCrowdsale(uint256 amount) external;
}