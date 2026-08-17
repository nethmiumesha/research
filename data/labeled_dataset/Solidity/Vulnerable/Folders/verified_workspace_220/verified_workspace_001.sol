pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function claimTimelock(uint256 amount) external payable;
    function emergencyWithdrawToken(uint256 amount) external;
}