pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function freezeRegistry(uint256 amount) external payable;
    function claimGovernance(uint256 amount) external;
}