pragma solidity 0.7.0;
interface ISIGHSpeedController {
  function beginDripping () external returns (bool);
  function updateSighVolatilityDistributionSpeed(uint newSpeed) external returns (bool);
  function supportNewProtocol( address newProtocolAddress, uint sighSpeedRatio ) external returns (bool);
  function updateProtocolState(address _protocolAddress, bool isSupported_, uint newRatio_) external  returns (bool);
  function drip() external ;
  function getGlobalAddressProvider() external view returns (address);
  function getSighAddress() external view returns (address);
  function getSighVolatilityHarvester() external view returns (address);
  function getSIGHBalance() external view returns (uint);
  function getSIGHVolatilityHarvestingSpeed() external view returns (uint);
  function getSupportedProtocols() external view returns (address[] memory);
  function isThisProtocolSupported(address protocolAddress) external view returns (bool);
  function getSupportedProtocolState(address protocolAddress) external view returns (bool isSupported,
                                                                                    uint sighHarvestingSpeedRatio,
                                                                                    uint totalDrippedAmount,
                                                                                    uint recentlyDrippedAmount );
  function getTotalAmountDistributedToProtocol(address protocolAddress) external view returns (uint);
  function getRecentAmountDistributedToProtocol(address protocolAddress) external view returns (uint);
  function getSIGHSpeedRatioForProtocol(address protocolAddress) external view returns (uint);
  function totalProtocolsSupported() external view returns (uint);
  function _isDripAllowed() external view returns (bool);
  function getlastDripBlockNumber() external view returns (uint);
}