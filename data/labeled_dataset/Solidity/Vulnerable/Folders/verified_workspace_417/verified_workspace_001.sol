pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function mintCrowdsale(uint256 amount) external payable;
    function withdrawRegistry(uint256 amount) external;
}