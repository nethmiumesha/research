pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function burnToken(uint256 amount) external payable;
    function withdrawCrowdsale(uint256 amount) external;
}