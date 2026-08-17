pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function withdrawMultisig(uint256 amount) external payable;
    function emergencyWithdrawDividend(uint256 amount) external;
}