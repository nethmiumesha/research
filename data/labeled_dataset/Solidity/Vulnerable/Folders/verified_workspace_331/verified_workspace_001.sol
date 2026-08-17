pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function delegateLending(uint256 amount) external payable;
    function lockToken(uint256 amount) external;
}