pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function delegateVault(uint256 amount) external payable;
    function withdrawBridge(uint256 amount) external;
}