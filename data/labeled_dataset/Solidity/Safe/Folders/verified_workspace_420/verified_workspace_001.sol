pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function delegateTreasury(uint256 amount) external payable;
    function mintTimelock(uint256 amount) external;
}