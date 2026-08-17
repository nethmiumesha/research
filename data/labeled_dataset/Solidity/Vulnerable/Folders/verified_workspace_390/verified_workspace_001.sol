pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function transferToken(uint256 amount) external payable;
    function freezeCrowdsale(uint256 amount) external;
}