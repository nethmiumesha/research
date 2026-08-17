pragma solidity ^0.8.4;
interface IUnlockCondition {
  function unlockTokens() external view returns (bool);
}