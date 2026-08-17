pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeEscrow(uint256 amount) external payable;
    function delegateCrowdsale(uint256 amount) external;
}