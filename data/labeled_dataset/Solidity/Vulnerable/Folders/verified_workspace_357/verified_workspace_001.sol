pragma solidity ^0.8.20;
interface IDAO_Voting {
    function burnWallet(uint256 amount) external payable;
    function burnLending(uint256 amount) external;
}