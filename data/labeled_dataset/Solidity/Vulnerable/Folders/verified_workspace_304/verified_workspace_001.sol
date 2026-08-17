pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function transferRegistry(uint256 amount) external payable;
    function approveVault(uint256 amount) external;
}