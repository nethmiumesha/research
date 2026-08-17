pragma solidity ^0.5.16;
import "./Owned.sol";
import "./PerpsV2SettingsMixin.sol";
import "./interfaces/IPerpsV2Settings.sol";
import "./interfaces/IPerpsV2Market.sol";
import "./interfaces/IFuturesMarketManager.sol";
contract PerpsV2Settings is Owned, PerpsV2SettingsMixin, IPerpsV2Settings {
    bytes32 internal constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";
    bytes32 public constant CONTRACT_NAME = "PerpsV2Settings";
    constructor(address _owner, address _resolver) public Owned(_owner) PerpsV2SettingsMixin(_resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = PerpsV2SettingsMixin.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }
    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }
    function baseFee(bytes32 _marketKey) external view returns (uint) {
        return _baseFee(_marketKey);
    }
    function baseFeeNextPrice(bytes32 _marketKey) external view returns (uint) {
        return _baseFeeNextPrice(_marketKey);
    }
    function nextPriceConfirmWindow(bytes32 _marketKey) public view returns (uint) {
        return _nextPriceConfirmWindow(_marketKey);
    }
    function maxLeverage(bytes32 _marketKey) public view returns (uint) {
        return _maxLeverage(_marketKey);
    }
    function maxSingleSideValueUSD(bytes32 _marketKey) public view returns (uint) {
        return _maxSingleSideValueUSD(_marketKey);
    }
    function maxFundingRate(bytes32 _marketKey) public view returns (uint) {
        return _maxFundingRate(_marketKey);
    }
    function skewScaleUSD(bytes32 _marketKey) public view returns (uint) {
        return _skewScaleUSD(_marketKey);
    }
    function parameters(bytes32 _marketKey)
        external
        view
        returns (
            uint baseFee,
            uint baseFeeNextPrice,
            uint nextPriceConfirmWindow,
            uint maxLeverage,
            uint maxSingleSideValueUSD,
            uint maxFundingRate,
            uint skewScaleUSD
        )
    {
        baseFee = _baseFee(_marketKey);
        baseFeeNextPrice = _baseFeeNextPrice(_marketKey);
        nextPriceConfirmWindow = _nextPriceConfirmWindow(_marketKey);
        maxLeverage = _maxLeverage(_marketKey);
        maxSingleSideValueUSD = _maxSingleSideValueUSD(_marketKey);
        maxFundingRate = _maxFundingRate(_marketKey);
        skewScaleUSD = _skewScaleUSD(_marketKey);
    }
    function minKeeperFee() external view returns (uint) {
        return _minKeeperFee();
    }
    function liquidationFeeRatio() external view returns (uint) {
        return _liquidationFeeRatio();
    }
    function liquidationBufferRatio() external view returns (uint) {
        return _liquidationBufferRatio();
    }
    function minInitialMargin() external view returns (uint) {
        return _minInitialMargin();
    }
    function _setParameter(
        bytes32 _marketKey,
        bytes32 key,
        uint value
    ) internal {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)), value);
        emit ParameterUpdated(_marketKey, key, value);
    }
    function setBaseFee(bytes32 _marketKey, uint _baseFee) public onlyOwner {
        require(_baseFee <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_BASE_FEE, _baseFee);
    }
    function setBaseFeeNextPrice(bytes32 _marketKey, uint _baseFeeNextPrice) public onlyOwner {
        require(_baseFeeNextPrice <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_BASE_FEE_NEXT_PRICE, _baseFeeNextPrice);
    }
    function setNextPriceConfirmWindow(bytes32 _marketKey, uint _nextPriceConfirmWindow) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW, _nextPriceConfirmWindow);
    }
    function setMaxLeverage(bytes32 _marketKey, uint _maxLeverage) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_LEVERAGE, _maxLeverage);
    }
    function setMaxSingleSideValueUSD(bytes32 _marketKey, uint _maxSingleSideValueUSD) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_SINGLE_SIDE_VALUE, _maxSingleSideValueUSD);
    }
    function _recomputeFunding(bytes32 _marketKey) internal {
        IPerpsV2Market market = IPerpsV2Market(_futuresMarketManager().marketForKey(_marketKey));
        if (market.marketSize() > 0) {
            market.recomputeFunding();
        }
    }
    function setMaxFundingRate(bytes32 _marketKey, uint _maxFundingRate) public onlyOwner {
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MAX_FUNDING_RATE, _maxFundingRate);
    }
    function setSkewScaleUSD(bytes32 _marketKey, uint _skewScaleUSD) public onlyOwner {
        require(_skewScaleUSD > 0, "cannot set skew scale 0");
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MIN_SKEW_SCALE, _skewScaleUSD);
    }
    function setParameters(
        bytes32 _marketKey,
        uint _baseFee,
        uint _baseFeeNextPrice,
        uint _nextPriceConfirmWindow,
        uint _maxLeverage,
        uint _maxSingleSideValueUSD,
        uint _maxFundingRate,
        uint _skewScaleUSD
    ) external onlyOwner {
        _recomputeFunding(_marketKey);
        setBaseFee(_marketKey, _baseFee);
        setBaseFeeNextPrice(_marketKey, _baseFeeNextPrice);
        setNextPriceConfirmWindow(_marketKey, _nextPriceConfirmWindow);
        setMaxLeverage(_marketKey, _maxLeverage);
        setMaxSingleSideValueUSD(_marketKey, _maxSingleSideValueUSD);
        setMaxFundingRate(_marketKey, _maxFundingRate);
        setSkewScaleUSD(_marketKey, _skewScaleUSD);
    }
    function setMinKeeperFee(uint _sUSD) external onlyOwner {
        require(_sUSD <= _minInitialMargin(), "min margin < liquidation fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE, _sUSD);
        emit MinKeeperFeeUpdated(_sUSD);
    }
    function setLiquidationFeeRatio(uint _ratio) external onlyOwner {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO, _ratio);
        emit LiquidationFeeRatioUpdated(_ratio);
    }
    function setLiquidationBufferRatio(uint _ratio) external onlyOwner {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_BUFFER_RATIO, _ratio);
        emit LiquidationBufferRatioUpdated(_ratio);
    }
    function setMinInitialMargin(uint _minMargin) external onlyOwner {
        require(_minKeeperFee() <= _minMargin, "min margin < liquidation fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN, _minMargin);
        emit MinInitialMarginUpdated(_minMargin);
    }
    event ParameterUpdated(bytes32 indexed marketKey, bytes32 indexed parameter, uint value);
    event MinKeeperFeeUpdated(uint sUSD);
    event LiquidationFeeRatioUpdated(uint bps);
    event LiquidationBufferRatioUpdated(uint bps);
    event MinInitialMarginUpdated(uint minMargin);
}