pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function approveVault(uint256 amount) external payable;
    function stakeStaking(uint256 amount) external;
}