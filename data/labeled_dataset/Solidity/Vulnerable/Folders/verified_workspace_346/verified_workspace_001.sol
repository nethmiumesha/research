pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function mintWallet(uint256 amount) external payable;
    function mintPool(uint256 amount) external;
}