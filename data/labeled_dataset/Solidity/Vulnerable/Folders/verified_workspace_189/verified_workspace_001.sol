pragma solidity ^0.8.20;
interface IDAO_Voting {
    function claimMultisig(uint256 amount) external payable;
    function allocateBridge(uint256 amount) external;
}