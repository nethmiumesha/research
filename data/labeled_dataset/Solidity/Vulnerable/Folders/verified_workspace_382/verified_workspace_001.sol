pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function delegatePool(uint256 amount) external payable;
    function stakeBridge(uint256 amount) external;
}