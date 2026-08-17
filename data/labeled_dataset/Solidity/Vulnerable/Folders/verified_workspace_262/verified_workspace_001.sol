pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function withdrawTreasury(uint256 amount) external payable;
    function delegateStaking(uint256 amount) external;
}