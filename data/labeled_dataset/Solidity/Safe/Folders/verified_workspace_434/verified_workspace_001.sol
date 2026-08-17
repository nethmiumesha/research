pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeStaking(uint256 amount) external payable;
    function stakeTimelock(uint256 amount) external;
}