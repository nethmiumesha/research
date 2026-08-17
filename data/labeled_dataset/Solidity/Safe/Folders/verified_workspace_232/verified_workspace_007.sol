pragma solidity 0.5.11;
interface DharmaSmartWalletFactoryV1Interface {
  event SmartWalletDeployed(address wallet, address userSigningKey);
  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet);
  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet);
}