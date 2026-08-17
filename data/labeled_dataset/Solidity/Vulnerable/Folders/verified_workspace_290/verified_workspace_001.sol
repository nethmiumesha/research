pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function executeWallet(uint256 amount) external payable;
    function withdrawCrowdsale(uint256 amount) external;
}