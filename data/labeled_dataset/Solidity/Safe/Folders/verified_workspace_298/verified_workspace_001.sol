pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function allocateLending(uint256 amount) external payable;
    function mintMultisig(uint256 amount) external;
}