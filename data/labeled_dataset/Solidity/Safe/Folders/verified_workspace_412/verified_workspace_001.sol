pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function withdrawCrowdsale(uint256 amount) external payable;
    function withdrawTreasury(uint256 amount) external;
}