pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function allocateCrowdsale(uint256 amount) external payable;
    function claimTimelock(uint256 amount) external;
}