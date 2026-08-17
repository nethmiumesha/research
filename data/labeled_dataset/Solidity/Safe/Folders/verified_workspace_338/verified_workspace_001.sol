pragma solidity ^0.8.20;
interface IDAO_Voting {
    function freezeMultisig(uint256 amount) external payable;
    function executeWallet(uint256 amount) external;
}