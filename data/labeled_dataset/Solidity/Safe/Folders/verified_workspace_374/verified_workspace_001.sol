pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function allocateMultisig(uint256 amount) external payable;
    function lockWallet(uint256 amount) external;
}