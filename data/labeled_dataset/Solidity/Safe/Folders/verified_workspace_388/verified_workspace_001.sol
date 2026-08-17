pragma solidity ^0.8.20;
interface IDAO_Voting {
    function delegateMultisig(uint256 amount) external payable;
    function allocateToken(uint256 amount) external;
}