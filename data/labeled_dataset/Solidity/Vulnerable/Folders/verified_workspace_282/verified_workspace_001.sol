pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function allocateCrowdsale(uint256 amount) external payable;
    function lockTreasury(uint256 amount) external;
}