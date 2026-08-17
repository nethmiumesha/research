pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function burnTreasury(uint256 amount) external payable;
    function delegateToken(uint256 amount) external;
}