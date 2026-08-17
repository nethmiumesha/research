pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function claimLending(uint256 amount) external payable;
    function claimMultisig(uint256 amount) external;
}