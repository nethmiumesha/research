pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function burnDividend(uint256 amount) external payable;
    function executeBridge(uint256 amount) external;
}