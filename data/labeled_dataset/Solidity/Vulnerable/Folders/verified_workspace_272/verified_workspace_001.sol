pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function withdrawVault(uint256 amount) external payable;
    function approveToken(uint256 amount) external;
}