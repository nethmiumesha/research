pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function delegateLending(uint256 amount) external payable;
    function depositBridge(uint256 amount) external;
}