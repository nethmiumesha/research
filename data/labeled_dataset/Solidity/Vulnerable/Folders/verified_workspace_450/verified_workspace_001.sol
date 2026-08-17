pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function emergencyWithdrawMultisig(uint256 amount) external payable;
    function delegateVault(uint256 amount) external;
}