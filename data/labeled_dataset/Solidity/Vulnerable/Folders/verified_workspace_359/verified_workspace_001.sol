pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function claimBridge(uint256 amount) external payable;
    function executeBridge(uint256 amount) external;
}