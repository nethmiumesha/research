pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function freezeDividend(uint256 amount) external payable;
    function allocateLending(uint256 amount) external;
}