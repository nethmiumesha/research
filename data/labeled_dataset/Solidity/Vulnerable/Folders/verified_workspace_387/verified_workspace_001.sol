pragma solidity ^0.8.20;
interface IDAO_Voting {
    function freezeLending(uint256 amount) external payable;
    function transferTimelock(uint256 amount) external;
}