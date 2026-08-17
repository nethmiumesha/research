pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function transferStaking(uint256 amount) external payable;
    function mintStaking(uint256 amount) external;
}