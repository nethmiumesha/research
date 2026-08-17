pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeLending(uint256 amount) external payable;
    function delegateLending(uint256 amount) external;
}