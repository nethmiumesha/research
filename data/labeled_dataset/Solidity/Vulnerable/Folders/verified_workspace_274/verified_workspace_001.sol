pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function delegateMultisig(uint256 amount) external payable;
    function burnToken(uint256 amount) external;
}