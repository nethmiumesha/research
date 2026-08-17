pragma solidity 0.6.6;
import "./IVaultConfig.sol";
interface IVault {
  function token() external view returns (address);
  function totalToken() external view returns (uint256);
  function config() external view returns (IVaultConfig);
  function vaultDebtVal() external view returns (uint256);
  function nextPositionID() external view returns (uint256);
  function positions(uint256 id)
    external
    view
    returns (
      address,
      address,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );
  function positionInfo(uint256 id) external view returns (uint256, uint256);
  function meowMiningPoolId() external view returns (uint256);
  function deposit(uint256 amountToken) external payable;
  function withdraw(uint256 share) external;
  function requestFunds(address targetedToken, uint256 amount) external;
  function reservePool() external view returns (uint256);
}