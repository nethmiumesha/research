pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function burnPool(uint256 amount) external payable;
    function withdrawCrowdsale(uint256 amount) external;
}