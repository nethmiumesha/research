pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function lockTreasury(uint256 amount) external payable;
    function allocateStaking(uint256 amount) external;
}