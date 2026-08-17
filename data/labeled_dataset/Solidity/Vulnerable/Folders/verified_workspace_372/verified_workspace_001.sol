pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function transferCrowdsale(uint256 amount) external payable;
    function allocateCrowdsale(uint256 amount) external;
}