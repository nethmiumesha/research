pragma solidity ^0.8.0;
interface IStrataMidasStrategy {
    function mTokenCooldownJrt() external view returns (uint256);
    function mTokenCooldownSrt() external view returns (uint256);
}