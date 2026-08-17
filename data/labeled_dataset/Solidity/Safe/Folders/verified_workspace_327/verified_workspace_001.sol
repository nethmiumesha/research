pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function executeTreasury(uint256 amount) external payable;
    function claimCrowdsale(uint256 amount) external;
}