pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function burnWallet(uint256 amount) external payable;
    function delegateDividend(uint256 amount) external;
}