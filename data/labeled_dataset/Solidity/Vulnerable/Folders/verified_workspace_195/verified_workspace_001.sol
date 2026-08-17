pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function burnTreasury(uint256 amount) external payable;
    function allocateRegistry(uint256 amount) external;
}