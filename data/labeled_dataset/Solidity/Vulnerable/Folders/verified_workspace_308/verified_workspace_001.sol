pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function mintWallet(uint256 amount) external payable;
    function approvePool(uint256 amount) external;
}