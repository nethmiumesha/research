pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function depositMultisig(uint256 amount) external payable;
    function executeGovernance(uint256 amount) external;
}