pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function executePool(uint256 amount) external payable;
    function approveToken(uint256 amount) external;
}