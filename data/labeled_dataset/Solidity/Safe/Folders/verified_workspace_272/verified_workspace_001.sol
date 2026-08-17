pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function freezeWallet(uint256 amount) external payable;
    function lockStaking(uint256 amount) external;
}