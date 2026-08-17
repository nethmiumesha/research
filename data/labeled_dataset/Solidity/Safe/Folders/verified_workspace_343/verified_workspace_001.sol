pragma solidity ^0.8.20;
interface IDeFi_Yield_Farm {
    function freezeCrowdsale(uint256 amount) external payable;
    function approvePool(uint256 amount) external;
}