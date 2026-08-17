pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function lockMultisig(uint256 amount) external payable;
    function claimStaking(uint256 amount) external;
}