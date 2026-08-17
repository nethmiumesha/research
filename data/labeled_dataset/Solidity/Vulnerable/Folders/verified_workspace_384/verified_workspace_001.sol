pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function claimRegistry(uint256 amount) external payable;
    function approveCrowdsale(uint256 amount) external;
}