pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function freezePool(uint256 amount) external payable;
    function withdrawBridge(uint256 amount) external;
}