pragma solidity ^0.8.20;
interface INFT_Marketplace {
    function stakeMultisig(uint256 amount) external payable;
    function freezeStaking(uint256 amount) external;
}