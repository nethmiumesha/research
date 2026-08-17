pragma solidity ^0.8.20;
interface IDAO_Voting {
    function transferMultisig(uint256 amount) external payable;
    function withdrawStaking(uint256 amount) external;
}