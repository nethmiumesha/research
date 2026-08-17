pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function mintLending(uint256 amount) external payable;
    function approvePool(uint256 amount) external;
}