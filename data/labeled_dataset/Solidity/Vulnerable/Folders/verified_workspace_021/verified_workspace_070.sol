pragma solidity ^0.5.16;
import "./MixinResolver.sol";
import "./interfaces/IFlexibleStorage.sol";
contract PerpsV2SettingsMixin is MixinResolver {
    bytes32 internal constant SETTING_CONTRACT_NAME = "PerpsV2Settings";
    bytes32 internal constant PARAMETER_BASE_FEE = "baseFee";
    bytes32 internal constant PARAMETER_BASE_FEE_NEXT_PRICE = "baseFeeNextPrice";
    bytes32 internal constant PARAMETER_NEXT_PRICE_CONFIRM_WINDOW = "nextPriceConfirmWindow";
    bytes32 internal constant PARAMETER_MAX_LEVERAGE = "maxLeverage";
    bytes32 internal constant PARAMETER_MAX_SINGLE_SIDE_VALUE = "maxSingleSideValueUSD";
    bytes32 internal constant PARAMETER_MAX_FUNDING_RATE = "maxFundingRate";
    bytes32 internal constant PARAMETER_MIN_SKEW_SCALE = "skewScaleUSD";
    bytes32 internal constant SETTING_MIN_KEEPER_FEE = "minKeeperFee";
    bytes32 internal constant SETTING_LIQUIDATION_FEE_RATIO = "liquidationFeeRatio";
    bytes32 internal constant SETTING_LIQUIDATION_BUFFER_RATIO = "liquidationBufferRatio";
    bytes32 internal constant SETTING_MIN_INITIAL_MARGIN = "minInitialMargin";
    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";
    constructor(address _resolver) internal MixinResolver(_resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }
    function _flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }
    function _parameter(bytes32 _marketKey, bytes32 key) internal view returns (uint value) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)));
    }
    function _baseFee(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_BASE_FEE);
    }
    function _baseFeeNextPrice(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_BASE_FEE_NEXT_PRICE);
    }
    function _nextPriceConfirmWindow(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW);
    }
    function _maxLeverage(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_LEVERAGE);
    }
    function _maxSingleSideValueUSD(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_SINGLE_SIDE_VALUE);
    }
    function _skewScaleUSD(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MIN_SKEW_SCALE);
    }
    function _maxFundingRate(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_FUNDING_RATE);
    }
    function _minKeeperFee() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE);
    }
    function _liquidationFeeRatio() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO);
    }
    function _liquidationBufferRatio() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_BUFFER_RATIO);
    }
    function _minInitialMargin() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN);
    }
}