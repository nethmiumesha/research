pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function stakeTreasury(uint256 amount) external payable;
    function depositWallet(uint256 amount) external;
}