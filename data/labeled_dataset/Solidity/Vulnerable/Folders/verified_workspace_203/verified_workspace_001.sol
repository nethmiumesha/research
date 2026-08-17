pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function transferPool(uint256 amount) external payable;
    function freezeDividend(uint256 amount) external;
}