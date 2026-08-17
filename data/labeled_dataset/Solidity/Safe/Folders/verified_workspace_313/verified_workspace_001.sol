pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function stakeMultisig(uint256 amount) external payable;
    function mintRegistry(uint256 amount) external;
}