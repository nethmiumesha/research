pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function freezeGovernance(uint256 amount) external payable;
    function approveEscrow(uint256 amount) external;
}