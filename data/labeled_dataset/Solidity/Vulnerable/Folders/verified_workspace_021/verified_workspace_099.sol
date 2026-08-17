pragma solidity ^0.5.16;
import "./Owned.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/ISystemSettings.sol";
import "./SystemSettingsLib.sol";
contract SystemSettings is Owned, MixinSystemSettings, ISystemSettings {
    using SystemSettingsLib for IFlexibleStorage;
    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {
        require(SETTING_CONTRACT_NAME == SystemSettingsLib.contractName(), "read and write keys not equal");
    }
    function CONTRACT_NAME() external view returns (bytes32) {
        return SystemSettingsLib.contractName();
    }
    function waitingPeriodSecs() external view returns (uint) {
        return getWaitingPeriodSecs();
    }
    function priceDeviationThresholdFactor() external view returns (uint) {
        return getPriceDeviationThresholdFactor();
    }
    function issuanceRatio() external view returns (uint) {
        return getIssuanceRatio();
    }
    function feePeriodDuration() external view returns (uint) {
        return getFeePeriodDuration();
    }
    function targetThreshold() external view returns (uint) {
        return getTargetThreshold();
    }
    function liquidationDelay() external view returns (uint) {
        return getLiquidationDelay();
    }
    function liquidationRatio() external view returns (uint) {
        return getLiquidationRatio();
    }
    function liquidationPenalty() external view returns (uint) {
        return getLiquidationPenalty();
    }
    function snxLiquidationPenalty() external view returns (uint) {
        return getSnxLiquidationPenalty();
    }
    function liquidationEscrowDuration() external view returns (uint) {
        return getLiquidationEscrowDuration();
    }
    function selfLiquidationPenalty() external view returns (uint) {
        return getSelfLiquidationPenalty();
    }
    function flagReward() external view returns (uint) {
        return getFlagReward();
    }
    function liquidateReward() external view returns (uint) {
        return getLiquidateReward();
    }
    function rateStalePeriod() external view returns (uint) {
        return getRateStalePeriod();
    }
    function exchangeFeeRate(bytes32 currencyKey) external view returns (uint) {
        return getExchangeFeeRate(currencyKey);
    }
    function exchangeDynamicFeeThreshold() external view returns (uint) {
        return getExchangeDynamicFeeConfig().threshold;
    }
    function exchangeDynamicFeeWeightDecay() external view returns (uint) {
        return getExchangeDynamicFeeConfig().weightDecay;
    }
    function exchangeDynamicFeeRounds() external view returns (uint) {
        return getExchangeDynamicFeeConfig().rounds;
    }
    function exchangeMaxDynamicFee() external view returns (uint) {
        return getExchangeDynamicFeeConfig().maxFee;
    }
    function minimumStakeTime() external view returns (uint) {
        return getMinimumStakeTime();
    }
    function debtSnapshotStaleTime() external view returns (uint) {
        return getDebtSnapshotStaleTime();
    }
    function aggregatorWarningFlags() external view returns (address) {
        return getAggregatorWarningFlags();
    }
    function tradingRewardsEnabled() external view returns (bool) {
        return getTradingRewardsEnabled();
    }
    function crossDomainMessageGasLimit(CrossDomainMessageGasLimits gasLimitType) external view returns (uint) {
        return getCrossDomainMessageGasLimit(gasLimitType);
    }
    function etherWrapperMaxETH() external view returns (uint) {
        return getEtherWrapperMaxETH();
    }
    function etherWrapperMintFeeRate() external view returns (uint) {
        return getEtherWrapperMintFeeRate();
    }
    function etherWrapperBurnFeeRate() external view returns (uint) {
        return getEtherWrapperBurnFeeRate();
    }
    function wrapperMaxTokenAmount(address wrapper) external view returns (uint) {
        return getWrapperMaxTokenAmount(wrapper);
    }
    function wrapperMintFeeRate(address wrapper) external view returns (int) {
        return getWrapperMintFeeRate(wrapper);
    }
    function wrapperBurnFeeRate(address wrapper) external view returns (int) {
        return getWrapperBurnFeeRate(wrapper);
    }
    function interactionDelay(address collateral) external view returns (uint) {
        return getInteractionDelay(collateral);
    }
    function collapseFeeRate(address collateral) external view returns (uint) {
        return getCollapseFeeRate(collateral);
    }
    function atomicMaxVolumePerBlock() external view returns (uint) {
        return getAtomicMaxVolumePerBlock();
    }
    function atomicTwapWindow() external view returns (uint) {
        return getAtomicTwapWindow();
    }
    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address) {
        return getAtomicEquivalentForDexPricing(currencyKey);
    }
    function atomicExchangeFeeRate(bytes32 currencyKey) external view returns (uint) {
        return getAtomicExchangeFeeRate(currencyKey);
    }
    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityConsiderationWindow(currencyKey);
    }
    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityUpdateThreshold(currencyKey);
    }
    function pureChainlinkPriceForAtomicSwapsEnabled(bytes32 currencyKey) external view returns (bool) {
        return getPureChainlinkPriceForAtomicSwapsEnabled(currencyKey);
    }
    function crossChainSynthTransferEnabled(bytes32 currencyKey) external view returns (uint) {
        return getCrossChainSynthTransferEnabled(currencyKey);
    }
    function setCrossDomainMessageGasLimit(CrossDomainMessageGasLimits _gasLimitType, uint _crossDomainMessageGasLimit)
        external
        onlyOwner
    {
        flexibleStorage().setCrossDomainMessageGasLimit(_getGasLimitSetting(_gasLimitType), _crossDomainMessageGasLimit);
        emit CrossDomainMessageGasLimitChanged(_gasLimitType, _crossDomainMessageGasLimit);
    }
    function setIssuanceRatio(uint ratio) external onlyOwner {
        flexibleStorage().setIssuanceRatio(SETTING_ISSUANCE_RATIO, ratio);
        emit IssuanceRatioUpdated(ratio);
    }
    function setTradingRewardsEnabled(bool _tradingRewardsEnabled) external onlyOwner {
        flexibleStorage().setTradingRewardsEnabled(SETTING_TRADING_REWARDS_ENABLED, _tradingRewardsEnabled);
        emit TradingRewardsEnabled(_tradingRewardsEnabled);
    }
    function setWaitingPeriodSecs(uint _waitingPeriodSecs) external onlyOwner {
        flexibleStorage().setWaitingPeriodSecs(SETTING_WAITING_PERIOD_SECS, _waitingPeriodSecs);
        emit WaitingPeriodSecsUpdated(_waitingPeriodSecs);
    }
    function setPriceDeviationThresholdFactor(uint _priceDeviationThresholdFactor) external onlyOwner {
        flexibleStorage().setPriceDeviationThresholdFactor(
            SETTING_PRICE_DEVIATION_THRESHOLD_FACTOR,
            _priceDeviationThresholdFactor
        );
        emit PriceDeviationThresholdUpdated(_priceDeviationThresholdFactor);
    }
    function setFeePeriodDuration(uint _feePeriodDuration) external onlyOwner {
        flexibleStorage().setFeePeriodDuration(SETTING_FEE_PERIOD_DURATION, _feePeriodDuration);
        emit FeePeriodDurationUpdated(_feePeriodDuration);
    }
    function setTargetThreshold(uint percent) external onlyOwner {
        uint threshold = flexibleStorage().setTargetThreshold(SETTING_TARGET_THRESHOLD, percent);
        emit TargetThresholdUpdated(threshold);
    }
    function setLiquidationDelay(uint time) external onlyOwner {
        flexibleStorage().setLiquidationDelay(SETTING_LIQUIDATION_DELAY, time);
        emit LiquidationDelayUpdated(time);
    }
    function setLiquidationRatio(uint _liquidationRatio) external onlyOwner {
        flexibleStorage().setLiquidationRatio(
            SETTING_LIQUIDATION_RATIO,
            _liquidationRatio,
            getSnxLiquidationPenalty(),
            getIssuanceRatio()
        );
        emit LiquidationRatioUpdated(_liquidationRatio);
    }
    function setLiquidationEscrowDuration(uint duration) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_ESCROW_DURATION, duration);
        emit LiquidationEscrowDurationUpdated(duration);
    }
    function setSnxLiquidationPenalty(uint penalty) external onlyOwner {
        flexibleStorage().setSnxLiquidationPenalty(SETTING_SNX_LIQUIDATION_PENALTY, penalty);
        emit SnxLiquidationPenaltyUpdated(penalty);
    }
    function setLiquidationPenalty(uint penalty) external onlyOwner {
        flexibleStorage().setLiquidationPenalty(SETTING_LIQUIDATION_PENALTY, penalty);
        emit LiquidationPenaltyUpdated(penalty);
    }
    function setSelfLiquidationPenalty(uint penalty) external onlyOwner {
        flexibleStorage().setSelfLiquidationPenalty(SETTING_SELF_LIQUIDATION_PENALTY, penalty);
        emit SelfLiquidationPenaltyUpdated(penalty);
    }
    function setFlagReward(uint reward) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_FLAG_REWARD, reward);
        emit FlagRewardUpdated(reward);
    }
    function setLiquidateReward(uint reward) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATE_REWARD, reward);
        emit LiquidateRewardUpdated(reward);
    }
    function setRateStalePeriod(uint period) external onlyOwner {
        flexibleStorage().setRateStalePeriod(SETTING_RATE_STALE_PERIOD, period);
        emit RateStalePeriodUpdated(period);
    }
    function setExchangeFeeRateForSynths(bytes32[] calldata synthKeys, uint256[] calldata exchangeFeeRates)
        external
        onlyOwner
    {
        flexibleStorage().setExchangeFeeRateForSynths(SETTING_EXCHANGE_FEE_RATE, synthKeys, exchangeFeeRates);
        for (uint i = 0; i < synthKeys.length; i++) {
            emit ExchangeFeeUpdated(synthKeys[i], exchangeFeeRates[i]);
        }
    }
    function setExchangeDynamicFeeThreshold(uint threshold) external onlyOwner {
        require(threshold != 0, "Threshold cannot be 0");
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_THRESHOLD, threshold);
        emit ExchangeDynamicFeeThresholdUpdated(threshold);
    }
    function setExchangeDynamicFeeWeightDecay(uint weightDecay) external onlyOwner {
        require(weightDecay != 0, "Weight decay cannot be 0");
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_WEIGHT_DECAY, weightDecay);
        emit ExchangeDynamicFeeWeightDecayUpdated(weightDecay);
    }
    function setExchangeDynamicFeeRounds(uint rounds) external onlyOwner {
        flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_EXCHANGE_DYNAMIC_FEE_ROUNDS, rounds);
        emit ExchangeDynamicFeeRoundsUpdated(rounds);
    }
    function setExchangeMaxDynamicFee(uint maxFee) external onlyOwner {
        flexibleStorage().setExchangeMaxDynamicFee(SETTING_EXCHANGE_MAX_DYNAMIC_FEE, maxFee);
        emit ExchangeMaxDynamicFeeUpdated(maxFee);
    }
    function setMinimumStakeTime(uint _seconds) external onlyOwner {
        flexibleStorage().setMinimumStakeTime(SETTING_MINIMUM_STAKE_TIME, _seconds);
        emit MinimumStakeTimeUpdated(_seconds);
    }
    function setDebtSnapshotStaleTime(uint _seconds) external onlyOwner {
        flexibleStorage().setDebtSnapshotStaleTime(SETTING_DEBT_SNAPSHOT_STALE_TIME, _seconds);
        emit DebtSnapshotStaleTimeUpdated(_seconds);
    }
    function setAggregatorWarningFlags(address _flags) external onlyOwner {
        flexibleStorage().setAggregatorWarningFlags(SETTING_AGGREGATOR_WARNING_FLAGS, _flags);
        emit AggregatorWarningFlagsUpdated(_flags);
    }
    function setEtherWrapperMaxETH(uint _maxETH) external onlyOwner {
        flexibleStorage().setEtherWrapperMaxETH(SETTING_ETHER_WRAPPER_MAX_ETH, _maxETH);
        emit EtherWrapperMaxETHUpdated(_maxETH);
    }
    function setEtherWrapperMintFeeRate(uint _rate) external onlyOwner {
        flexibleStorage().setEtherWrapperMintFeeRate(SETTING_ETHER_WRAPPER_MINT_FEE_RATE, _rate);
        emit EtherWrapperMintFeeRateUpdated(_rate);
    }
    function setEtherWrapperBurnFeeRate(uint _rate) external onlyOwner {
        flexibleStorage().setEtherWrapperBurnFeeRate(SETTING_ETHER_WRAPPER_BURN_FEE_RATE, _rate);
        emit EtherWrapperBurnFeeRateUpdated(_rate);
    }
    function setWrapperMaxTokenAmount(address _wrapper, uint _maxTokenAmount) external onlyOwner {
        flexibleStorage().setWrapperMaxTokenAmount(SETTING_WRAPPER_MAX_TOKEN_AMOUNT, _wrapper, _maxTokenAmount);
        emit WrapperMaxTokenAmountUpdated(_wrapper, _maxTokenAmount);
    }
    function setWrapperMintFeeRate(address _wrapper, int _rate) external onlyOwner {
        flexibleStorage().setWrapperMintFeeRate(
            SETTING_WRAPPER_MINT_FEE_RATE,
            _wrapper,
            _rate,
            getWrapperBurnFeeRate(_wrapper)
        );
        emit WrapperMintFeeRateUpdated(_wrapper, _rate);
    }
    function setWrapperBurnFeeRate(address _wrapper, int _rate) external onlyOwner {
        flexibleStorage().setWrapperBurnFeeRate(
            SETTING_WRAPPER_BURN_FEE_RATE,
            _wrapper,
            _rate,
            getWrapperMintFeeRate(_wrapper)
        );
        emit WrapperBurnFeeRateUpdated(_wrapper, _rate);
    }
    function setInteractionDelay(address _collateral, uint _interactionDelay) external onlyOwner {
        flexibleStorage().setInteractionDelay(SETTING_INTERACTION_DELAY, _collateral, _interactionDelay);
        emit InteractionDelayUpdated(_interactionDelay);
    }
    function setCollapseFeeRate(address _collateral, uint _collapseFeeRate) external onlyOwner {
        flexibleStorage().setCollapseFeeRate(SETTING_COLLAPSE_FEE_RATE, _collateral, _collapseFeeRate);
        emit CollapseFeeRateUpdated(_collapseFeeRate);
    }
    function setAtomicMaxVolumePerBlock(uint _maxVolume) external onlyOwner {
        flexibleStorage().setAtomicMaxVolumePerBlock(SETTING_ATOMIC_MAX_VOLUME_PER_BLOCK, _maxVolume);
        emit AtomicMaxVolumePerBlockUpdated(_maxVolume);
    }
    function setAtomicTwapWindow(uint _window) external onlyOwner {
        flexibleStorage().setAtomicTwapWindow(SETTING_ATOMIC_TWAP_WINDOW, _window);
        emit AtomicTwapWindowUpdated(_window);
    }
    function setAtomicEquivalentForDexPricing(bytes32 _currencyKey, address _equivalent) external onlyOwner {
        flexibleStorage().setAtomicEquivalentForDexPricing(
            SETTING_ATOMIC_EQUIVALENT_FOR_DEX_PRICING,
            _currencyKey,
            _equivalent
        );
        emit AtomicEquivalentForDexPricingUpdated(_currencyKey, _equivalent);
    }
    function setAtomicExchangeFeeRate(bytes32 _currencyKey, uint256 _exchangeFeeRate) external onlyOwner {
        flexibleStorage().setAtomicExchangeFeeRate(SETTING_ATOMIC_EXCHANGE_FEE_RATE, _currencyKey, _exchangeFeeRate);
        emit AtomicExchangeFeeUpdated(_currencyKey, _exchangeFeeRate);
    }
    function setAtomicVolatilityConsiderationWindow(bytes32 _currencyKey, uint _window) external onlyOwner {
        flexibleStorage().setAtomicVolatilityConsiderationWindow(
            SETTING_ATOMIC_VOLATILITY_CONSIDERATION_WINDOW,
            _currencyKey,
            _window
        );
        emit AtomicVolatilityConsiderationWindowUpdated(_currencyKey, _window);
    }
    function setAtomicVolatilityUpdateThreshold(bytes32 _currencyKey, uint _threshold) external onlyOwner {
        flexibleStorage().setAtomicVolatilityUpdateThreshold(
            SETTING_ATOMIC_VOLATILITY_UPDATE_THRESHOLD,
            _currencyKey,
            _threshold
        );
        emit AtomicVolatilityUpdateThresholdUpdated(_currencyKey, _threshold);
    }
    function setPureChainlinkPriceForAtomicSwapsEnabled(bytes32 _currencyKey, bool _enabled) external onlyOwner {
        flexibleStorage().setPureChainlinkPriceForAtomicSwapsEnabled(
            SETTING_PURE_CHAINLINK_PRICE_FOR_ATOMIC_SWAPS_ENABLED,
            _currencyKey,
            _enabled
        );
        emit PureChainlinkPriceForAtomicSwapsEnabledUpdated(_currencyKey, _enabled);
    }
    function setCrossChainSynthTransferEnabled(bytes32 _currencyKey, uint _value) external onlyOwner {
        flexibleStorage().setCrossChainSynthTransferEnabled(SETTING_CROSS_SYNTH_TRANSFER_ENABLED, _currencyKey, _value);
        emit CrossChainSynthTransferEnabledUpdated(_currencyKey, _value);
    }
    event CrossDomainMessageGasLimitChanged(CrossDomainMessageGasLimits gasLimitType, uint newLimit);
    event IssuanceRatioUpdated(uint newRatio);
    event TradingRewardsEnabled(bool enabled);
    event WaitingPeriodSecsUpdated(uint waitingPeriodSecs);
    event PriceDeviationThresholdUpdated(uint threshold);
    event FeePeriodDurationUpdated(uint newFeePeriodDuration);
    event TargetThresholdUpdated(uint newTargetThreshold);
    event LiquidationDelayUpdated(uint newDelay);
    event LiquidationRatioUpdated(uint newRatio);
    event LiquidationEscrowDurationUpdated(uint newDuration);
    event LiquidationPenaltyUpdated(uint newPenalty);
    event SnxLiquidationPenaltyUpdated(uint newPenalty);
    event SelfLiquidationPenaltyUpdated(uint newPenalty);
    event FlagRewardUpdated(uint newReward);
    event LiquidateRewardUpdated(uint newReward);
    event RateStalePeriodUpdated(uint rateStalePeriod);
    event ExchangeFeeUpdated(bytes32 synthKey, uint newExchangeFeeRate);
    event ExchangeDynamicFeeThresholdUpdated(uint dynamicFeeThreshold);
    event ExchangeDynamicFeeWeightDecayUpdated(uint dynamicFeeWeightDecay);
    event ExchangeDynamicFeeRoundsUpdated(uint dynamicFeeRounds);
    event ExchangeMaxDynamicFeeUpdated(uint maxDynamicFee);
    event MinimumStakeTimeUpdated(uint minimumStakeTime);
    event DebtSnapshotStaleTimeUpdated(uint debtSnapshotStaleTime);
    event AggregatorWarningFlagsUpdated(address flags);
    event EtherWrapperMaxETHUpdated(uint maxETH);
    event EtherWrapperMintFeeRateUpdated(uint rate);
    event EtherWrapperBurnFeeRateUpdated(uint rate);
    event WrapperMaxTokenAmountUpdated(address wrapper, uint maxTokenAmount);
    event WrapperMintFeeRateUpdated(address wrapper, int rate);
    event WrapperBurnFeeRateUpdated(address wrapper, int rate);
    event InteractionDelayUpdated(uint interactionDelay);
    event CollapseFeeRateUpdated(uint collapseFeeRate);
    event AtomicMaxVolumePerBlockUpdated(uint newMaxVolume);
    event AtomicTwapWindowUpdated(uint newWindow);
    event AtomicEquivalentForDexPricingUpdated(bytes32 synthKey, address equivalent);
    event AtomicExchangeFeeUpdated(bytes32 synthKey, uint newExchangeFeeRate);
    event AtomicVolatilityConsiderationWindowUpdated(bytes32 synthKey, uint newVolatilityConsiderationWindow);
    event AtomicVolatilityUpdateThresholdUpdated(bytes32 synthKey, uint newVolatilityUpdateThreshold);
    event PureChainlinkPriceForAtomicSwapsEnabledUpdated(bytes32 synthKey, bool enabled);
    event CrossChainSynthTransferEnabledUpdated(bytes32 synthKey, uint value);
}