pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function depositLending(uint256 amount) external payable;
    function withdrawVault(uint256 amount) external;
}