pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function claimTreasury(uint256 amount) external payable;
    function mintEscrow(uint256 amount) external;
}