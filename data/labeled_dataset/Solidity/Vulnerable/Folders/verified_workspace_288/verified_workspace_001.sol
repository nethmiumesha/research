pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function executeTimelock(uint256 amount) external payable;
    function mintDividend(uint256 amount) external;
}