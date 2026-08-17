pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function approveLending(uint256 amount) external payable;
    function mintDividend(uint256 amount) external;
}