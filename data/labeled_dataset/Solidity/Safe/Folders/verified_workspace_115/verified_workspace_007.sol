pragma solidity 0.7.0;
interface ILendingPoolConfigurator {
    function initInstrument( address _instrument, uint8 _underlyingAssetDecimals, address _interestRateStrategyAddress ) external;
    function removeLastAddedInstrument( address _instrumentToRemove) external ;
    function enableInstrumentAsCollateral( address _instrument, uint256 _baseLTVasCollateral, uint256 _liquidationThreshold, uint256 _liquidationBonus ) external;
    function disableInstrumentAsCollateral(address _instrument) external;
    function switchInstrument(address _instrument, bool switch_) external;
    function switchInstrumentStableBorrowRate(address _instrument, bool borrowRateSwitch) external;
    function switchBorrowingOnInstrument(address _instrument, bool _stableBorrowRateEnabled) external;
    function switchInstrumentFreeze(address _instrument, bool switch_) external;
    function setInstrumentBaseLTVasCollateral(address _instrument, uint256 _ltv) external;
    function setInstrumentLiquidationThreshold(address _instrument, uint256 _threshold) external;
    function setInstrumentLiquidationBonus(address _instrument, uint256 _bonus) external;
    function setInstrumentInterestRateStrategyAddress(address _instrument, address _rateStrategyAddress) external ;
    function refreshLendingPoolCoreConfiguration() external ;
    function refreshLendingPoolConfiguration() external ;
    function updateSIGHSpeedRatioForAnInstrument(address instrument_, uint supplierRatio) external ;
    function supportNewAsset(address asset_, address source_) external;
    function setAssetSources(address[] calldata _assets, address[] calldata _sources) external;
    function setFallbackOracle(address _fallbackOracle) external ;
}