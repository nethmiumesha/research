pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function withdrawToken(uint256 amount) external payable;
    function lockWallet(uint256 amount) external;
}