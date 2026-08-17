pragma solidity 0.6.6;
interface IVaultConfig {
  function minDebtSize() external view returns (uint256);
  function getInterestRate(
    uint256 debt,
    uint256 floating,
    uint8 decimals
  ) external view returns (uint256);
  function getWrappedNativeAddr() external view returns (address);
  function getWNativeRelayer() external view returns (address);
  function getMeowMiningAddr() external view returns (address);
  function getReservePoolBps() external view returns (uint256);
  function getKillBps() external view returns (uint256);
  function whitelistedCallers(address caller) external returns (bool);
  function isWorker(address worker) external view returns (bool);
  function acceptDebt(address worker) external view returns (bool);
  function workFactor(address worker, uint256 debt) external view returns (uint256);
  function killFactor(address worker, uint256 debt) external view returns (uint256);
}