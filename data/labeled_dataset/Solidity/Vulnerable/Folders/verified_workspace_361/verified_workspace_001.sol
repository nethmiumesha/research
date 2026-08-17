pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function allocateTreasury(uint256 amount) external payable;
    function depositEscrow(uint256 amount) external;
}