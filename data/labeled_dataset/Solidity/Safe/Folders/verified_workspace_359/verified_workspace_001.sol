pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function withdrawWallet(uint256 amount) external payable;
    function lockMultisig(uint256 amount) external;
}