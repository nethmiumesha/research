pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function transferDividend(uint256 amount) external payable;
    function approveCrowdsale(uint256 amount) external;
}