pragma solidity ^0.8.20;
interface IDAO_Voting {
    function withdrawMultisig(uint256 amount) external payable;
    function approveCrowdsale(uint256 amount) external;
}