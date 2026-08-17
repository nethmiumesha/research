pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function mintPool(uint256 amount) external payable;
    function emergencyWithdrawRegistry(uint256 amount) external;
}