pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function freezeBridge(uint256 amount) external payable;
    function mintVault(uint256 amount) external;
}