pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function allocateToken(uint256 amount) external payable;
    function burnTimelock(uint256 amount) external;
}