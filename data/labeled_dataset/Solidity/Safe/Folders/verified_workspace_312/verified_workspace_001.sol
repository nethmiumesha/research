pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeTimelock(uint256 amount) external payable;
    function stakeRegistry(uint256 amount) external;
}