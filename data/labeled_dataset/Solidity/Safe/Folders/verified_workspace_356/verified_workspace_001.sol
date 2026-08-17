pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function withdrawGovernance(uint256 amount) external payable;
    function claimRegistry(uint256 amount) external;
}