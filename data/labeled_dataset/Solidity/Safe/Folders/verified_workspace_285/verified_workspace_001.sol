pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function approveWallet(uint256 amount) external payable;
    function burnVault(uint256 amount) external;
}