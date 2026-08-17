pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function allocateEscrow(uint256 amount) external payable;
    function lockRegistry(uint256 amount) external;
}