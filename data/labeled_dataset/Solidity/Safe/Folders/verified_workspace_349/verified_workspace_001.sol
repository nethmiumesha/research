pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function lockTreasury(uint256 amount) external payable;
    function transferWallet(uint256 amount) external;
}