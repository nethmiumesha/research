pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function burnWallet(uint256 amount) external payable;
    function mintVault(uint256 amount) external;
}