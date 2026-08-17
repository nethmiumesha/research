pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function approveMultisig(uint256 amount) external payable;
    function delegateBridge(uint256 amount) external;
}