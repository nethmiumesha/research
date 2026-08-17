pragma solidity ^0.5.16;
import "./Owned.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/IIssuer.sol";
import "./SafeDecimalMath.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/ISynthetix.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/ISynthetixState.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IDelegateApprovals.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IHasBalance.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ILiquidations.sol";
import "./interfaces/ICollateralManager.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/ISynthRedeemer.sol";
import "./Proxyable.sol";
interface IProxy {
    function target() external view returns (address);
}
interface IIssuerInternalDebtCache {
    function updateCachedSynthDebtWithRate(bytes32 currencyKey, uint currencyRate) external;
    function updateCachedSynthDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external;
    function updateDebtCacheValidity(bool currentlyInvalid) external;
    function totalNonSnxBackedDebt() external view returns (uint excludedDebt, bool isInvalid);
    function cacheInfo()
        external
        view
        returns (
            uint cachedDebt,
            uint timestamp,
            bool isInvalid,
            bool isStale
        );
    function updateCachedsUSDDebt(int amount) external;
}
contract Issuer is Owned, MixinSystemSettings, IIssuer {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    bytes32 public constant CONTRACT_NAME = "Issuer";
    ISynth[] public availableSynths;
    mapping(bytes32 => ISynth) public synths;
    mapping(address => bytes32) public synthsByAddress;
    bytes32 internal constant sUSD = "sUSD";
    bytes32 internal constant sETH = "sETH";
    bytes32 internal constant SNX = "SNX";
    bytes32 internal constant LAST_ISSUE_EVENT = "lastIssueEvent";
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_SYNTHETIXSTATE = "SynthetixState";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_COLLATERALMANAGER = "CollateralManager";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_SYNTHETIXESCROW = "SynthetixEscrow";
    bytes32 private constant CONTRACT_LIQUIDATIONS = "Liquidations";
    bytes32 private constant CONTRACT_DEBTCACHE = "DebtCache";
    bytes32 private constant CONTRACT_SYNTHREDEEMER = "SynthRedeemer";
    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](12);
        newAddresses[0] = CONTRACT_SYNTHETIX;
        newAddresses[1] = CONTRACT_EXCHANGER;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_SYNTHETIXSTATE;
        newAddresses[4] = CONTRACT_FEEPOOL;
        newAddresses[5] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[6] = CONTRACT_REWARDESCROW_V2;
        newAddresses[7] = CONTRACT_SYNTHETIXESCROW;
        newAddresses[8] = CONTRACT_LIQUIDATIONS;
        newAddresses[9] = CONTRACT_DEBTCACHE;
        newAddresses[10] = CONTRACT_COLLATERALMANAGER;
        newAddresses[11] = CONTRACT_SYNTHREDEEMER;
        return combineArrays(existingAddresses, newAddresses);
    }
    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }
    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }
    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }
    function synthetixState() internal view returns (ISynthetixState) {
        return ISynthetixState(requireAndGetAddress(CONTRACT_SYNTHETIXSTATE));
    }
    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }
    function liquidations() internal view returns (ILiquidations) {
        return ILiquidations(requireAndGetAddress(CONTRACT_LIQUIDATIONS));
    }
    function delegateApprovals() internal view returns (IDelegateApprovals) {
        return IDelegateApprovals(requireAndGetAddress(CONTRACT_DELEGATEAPPROVALS));
    }
    function collateralManager() internal view returns (ICollateralManager) {
        return ICollateralManager(requireAndGetAddress(CONTRACT_COLLATERALMANAGER));
    }
    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }
    function synthetixEscrow() internal view returns (IHasBalance) {
        return IHasBalance(requireAndGetAddress(CONTRACT_SYNTHETIXESCROW));
    }
    function debtCache() internal view returns (IIssuerInternalDebtCache) {
        return IIssuerInternalDebtCache(requireAndGetAddress(CONTRACT_DEBTCACHE));
    }
    function synthRedeemer() internal view returns (ISynthRedeemer) {
        return ISynthRedeemer(requireAndGetAddress(CONTRACT_SYNTHREDEEMER));
    }
    function issuanceRatio() external view returns (uint) {
        return getIssuanceRatio();
    }
    function _availableCurrencyKeysWithOptionalSNX(bool withSNX) internal view returns (bytes32[] memory) {
        bytes32[] memory currencyKeys = new bytes32[](availableSynths.length + (withSNX ? 1 : 0));
        for (uint i = 0; i < availableSynths.length; i++) {
            currencyKeys[i] = synthsByAddress[address(availableSynths[i])];
        }
        if (withSNX) {
            currencyKeys[availableSynths.length] = SNX;
        }
        return currencyKeys;
    }
    function _totalIssuedSynths(bytes32 currencyKey, bool excludeCollateral)
        internal
        view
        returns (uint totalIssued, bool anyRateIsInvalid)
    {
        (uint debt, , bool cacheIsInvalid, bool cacheIsStale) = debtCache().cacheInfo();
        anyRateIsInvalid = cacheIsInvalid || cacheIsStale;
        IExchangeRates exRates = exchangeRates();
        if (!excludeCollateral) {
            (uint nonSnxDebt, bool invalid) = debtCache().totalNonSnxBackedDebt();
            debt = debt.add(nonSnxDebt);
            anyRateIsInvalid = anyRateIsInvalid || invalid;
        }
        if (currencyKey == sUSD) {
            return (debt, anyRateIsInvalid);
        }
        (uint currencyRate, bool currencyRateInvalid) = exRates.rateAndInvalid(currencyKey);
        return (debt.divideDecimalRound(currencyRate), anyRateIsInvalid || currencyRateInvalid);
    }
    function _debtBalanceOfAndTotalDebt(address _issuer, bytes32 currencyKey)
        internal
        view
        returns (
            uint debtBalance,
            uint totalSystemValue,
            bool anyRateIsInvalid
        )
    {
        ISynthetixState state = synthetixState();
        (uint initialDebtOwnership, uint debtEntryIndex) = state.issuanceData(_issuer);
        (totalSystemValue, anyRateIsInvalid) = _totalIssuedSynths(currencyKey, true);
        if (initialDebtOwnership == 0) return (0, totalSystemValue, anyRateIsInvalid);
        uint currentDebtOwnership =
            state
                .lastDebtLedgerEntry()
                .divideDecimalRoundPrecise(state.debtLedger(debtEntryIndex))
                .multiplyDecimalRoundPrecise(initialDebtOwnership);
        uint highPrecisionBalance =
            totalSystemValue.decimalToPreciseDecimal().multiplyDecimalRoundPrecise(currentDebtOwnership);
        debtBalance = highPrecisionBalance.preciseDecimalToDecimal();
    }
    function _canBurnSynths(address account) internal view returns (bool) {
        return now >= _lastIssueEvent(account).add(getMinimumStakeTime());
    }
    function _lastIssueEvent(address account) internal view returns (uint) {
        return flexibleStorage().getUIntValue(CONTRACT_NAME, keccak256(abi.encodePacked(LAST_ISSUE_EVENT, account)));
    }
    function _remainingIssuableSynths(address _issuer)
        internal
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt,
            bool anyRateIsInvalid
        )
    {
        (alreadyIssued, totalSystemDebt, anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(_issuer, sUSD);
        (uint issuable, bool isInvalid) = _maxIssuableSynths(_issuer);
        maxIssuable = issuable;
        anyRateIsInvalid = anyRateIsInvalid || isInvalid;
        if (alreadyIssued >= maxIssuable) {
            maxIssuable = 0;
        } else {
            maxIssuable = maxIssuable.sub(alreadyIssued);
        }
    }
    function _snxToUSD(uint amount, uint snxRate) internal pure returns (uint) {
        return amount.multiplyDecimalRound(snxRate);
    }
    function _usdToSnx(uint amount, uint snxRate) internal pure returns (uint) {
        return amount.divideDecimalRound(snxRate);
    }
    function _maxIssuableSynths(address _issuer) internal view returns (uint, bool) {
        (uint snxRate, bool isInvalid) = exchangeRates().rateAndInvalid(SNX);
        uint destinationValue = _snxToUSD(_collateral(_issuer), snxRate);
        return (destinationValue.multiplyDecimal(getIssuanceRatio()), isInvalid);
    }
    function _collateralisationRatio(address _issuer) internal view returns (uint, bool) {
        uint totalOwnedSynthetix = _collateral(_issuer);
        (uint debtBalance, , bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(_issuer, SNX);
        if (totalOwnedSynthetix == 0) return (0, anyRateIsInvalid);
        return (debtBalance.divideDecimalRound(totalOwnedSynthetix), anyRateIsInvalid);
    }
    function _collateral(address account) internal view returns (uint) {
        uint balance = IERC20(address(synthetix())).balanceOf(account);
        if (address(synthetixEscrow()) != address(0)) {
            balance = balance.add(synthetixEscrow().balanceOf(account));
        }
        if (address(rewardEscrowV2()) != address(0)) {
            balance = balance.add(rewardEscrowV2().balanceOf(account));
        }
        return balance;
    }
    function minimumStakeTime() external view returns (uint) {
        return getMinimumStakeTime();
    }
    function canBurnSynths(address account) external view returns (bool) {
        return _canBurnSynths(account);
    }
    function availableCurrencyKeys() external view returns (bytes32[] memory) {
        return _availableCurrencyKeysWithOptionalSNX(false);
    }
    function availableSynthCount() external view returns (uint) {
        return availableSynths.length;
    }
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid) {
        (, anyRateInvalid) = exchangeRates().ratesAndInvalidForCurrencies(_availableCurrencyKeysWithOptionalSNX(true));
    }
    function totalIssuedSynths(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint totalIssued) {
        (totalIssued, ) = _totalIssuedSynths(currencyKey, excludeOtherCollateral);
    }
    function lastIssueEvent(address account) external view returns (uint) {
        return _lastIssueEvent(account);
    }
    function collateralisationRatio(address _issuer) external view returns (uint cratio) {
        (cratio, ) = _collateralisationRatio(_issuer);
    }
    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid)
    {
        return _collateralisationRatio(_issuer);
    }
    function collateral(address account) external view returns (uint) {
        return _collateral(account);
    }
    function debtBalanceOf(address _issuer, bytes32 currencyKey) external view returns (uint debtBalance) {
        ISynthetixState state = synthetixState();
        (uint initialDebtOwnership, ) = state.issuanceData(_issuer);
        if (initialDebtOwnership == 0) return 0;
        (debtBalance, , ) = _debtBalanceOfAndTotalDebt(_issuer, currencyKey);
    }
    function remainingIssuableSynths(address _issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        )
    {
        (maxIssuable, alreadyIssued, totalSystemDebt, ) = _remainingIssuableSynths(_issuer);
    }
    function maxIssuableSynths(address _issuer) external view returns (uint) {
        (uint maxIssuable, ) = _maxIssuableSynths(_issuer);
        return maxIssuable;
    }
    function transferableSynthetixAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid)
    {
        uint debtBalance;
        (debtBalance, , anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(account, SNX);
        uint lockedSynthetixValue = debtBalance.divideDecimalRound(getIssuanceRatio());
        if (lockedSynthetixValue >= balance) {
            transferable = 0;
        } else {
            transferable = balance.sub(lockedSynthetixValue);
        }
    }
    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory) {
        uint numKeys = currencyKeys.length;
        ISynth[] memory addresses = new ISynth[](numKeys);
        for (uint i = 0; i < numKeys; i++) {
            addresses[i] = synths[currencyKeys[i]];
        }
        return addresses;
    }
    function _addSynth(ISynth synth) internal {
        bytes32 currencyKey = synth.currencyKey();
        require(synths[currencyKey] == ISynth(0), "Synth exists");
        require(synthsByAddress[address(synth)] == bytes32(0), "Synth address already exists");
        availableSynths.push(synth);
        synths[currencyKey] = synth;
        synthsByAddress[address(synth)] = currencyKey;
        emit SynthAdded(currencyKey, address(synth));
    }
    function addSynth(ISynth synth) external onlyOwner {
        _addSynth(synth);
        debtCache().updateDebtCacheValidity(true);
    }
    function addSynths(ISynth[] calldata synthsToAdd) external onlyOwner {
        uint numSynths = synthsToAdd.length;
        for (uint i = 0; i < numSynths; i++) {
            _addSynth(synthsToAdd[i]);
        }
        debtCache().updateDebtCacheValidity(true);
    }
    function _removeSynth(bytes32 currencyKey) internal {
        address synthToRemove = address(synths[currencyKey]);
        require(synthToRemove != address(0), "Synth does not exist");
        require(currencyKey != sUSD, "Cannot remove synth");
        uint synthSupply = IERC20(synthToRemove).totalSupply();
        if (synthSupply > 0) {
            (uint amountOfsUSD, uint rateToRedeem, ) =
                exchangeRates().effectiveValueAndRates(currencyKey, synthSupply, "sUSD");
            require(rateToRedeem > 0, "Cannot remove synth to redeem without rate");
            ISynthRedeemer _synthRedeemer = synthRedeemer();
            synths[sUSD].issue(address(_synthRedeemer), amountOfsUSD);
            debtCache().updateCachedSynthDebtWithRate(sUSD, SafeDecimalMath.unit());
            _synthRedeemer.deprecate(IERC20(address(Proxyable(address(synthToRemove)).proxy())), rateToRedeem);
        }
        for (uint i = 0; i < availableSynths.length; i++) {
            if (address(availableSynths[i]) == synthToRemove) {
                delete availableSynths[i];
                availableSynths[i] = availableSynths[availableSynths.length - 1];
                availableSynths.length--;
                break;
            }
        }
        delete synthsByAddress[synthToRemove];
        delete synths[currencyKey];
        emit SynthRemoved(currencyKey, synthToRemove);
    }
    function removeSynth(bytes32 currencyKey) external onlyOwner {
        IIssuerInternalDebtCache cache = debtCache();
        cache.updateCachedSynthDebtWithRate(currencyKey, 0);
        cache.updateDebtCacheValidity(true);
        _removeSynth(currencyKey);
    }
    function removeSynths(bytes32[] calldata currencyKeys) external onlyOwner {
        uint numKeys = currencyKeys.length;
        IIssuerInternalDebtCache cache = debtCache();
        uint[] memory zeroRates = new uint[](numKeys);
        cache.updateCachedSynthDebtsWithRates(currencyKeys, zeroRates);
        cache.updateDebtCacheValidity(true);
        for (uint i = 0; i < numKeys; i++) {
            _removeSynth(currencyKeys[i]);
        }
    }
    function issueSynths(address from, uint amount) external onlySynthetix {
        _issueSynths(from, amount, false);
    }
    function issueMaxSynths(address from) external onlySynthetix {
        _issueSynths(from, 0, true);
    }
    function issueSynthsOnBehalf(
        address issueForAddress,
        address from,
        uint amount
    ) external onlySynthetix {
        _requireCanIssueOnBehalf(issueForAddress, from);
        _issueSynths(issueForAddress, amount, false);
    }
    function issueMaxSynthsOnBehalf(address issueForAddress, address from) external onlySynthetix {
        _requireCanIssueOnBehalf(issueForAddress, from);
        _issueSynths(issueForAddress, 0, true);
    }
    function burnSynths(address from, uint amount) external onlySynthetix {
        _voluntaryBurnSynths(from, amount, false);
    }
    function burnSynthsOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external onlySynthetix {
        _requireCanBurnOnBehalf(burnForAddress, from);
        _voluntaryBurnSynths(burnForAddress, amount, false);
    }
    function burnSynthsToTarget(address from) external onlySynthetix {
        _voluntaryBurnSynths(from, 0, true);
    }
    function burnSynthsToTargetOnBehalf(address burnForAddress, address from) external onlySynthetix {
        _requireCanBurnOnBehalf(burnForAddress, from);
        _voluntaryBurnSynths(burnForAddress, 0, true);
    }
    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint balance
    ) external onlySynthRedeemer {
        ISynth(IProxy(deprecatedSynthProxy).target()).burn(account, balance);
    }
    function liquidateDelinquentAccount(
        address account,
        uint susdAmount,
        address liquidator
    ) external onlySynthetix returns (uint totalRedeemed, uint amountToLiquidate) {
        require(!exchanger().hasWaitingPeriodOrSettlementOwing(liquidator, sUSD), "sUSD needs to be settled");
        require(liquidations().isOpenForLiquidation(account), "Account not open for liquidation");
        require(IERC20(address(synths[sUSD])).balanceOf(liquidator) >= susdAmount, "Not enough sUSD");
        uint liquidationPenalty = liquidations().liquidationPenalty();
        (uint debtBalance, uint totalDebtIssued, bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(account, sUSD);
        (uint snxRate, bool snxRateInvalid) = exchangeRates().rateAndInvalid(SNX);
        _requireRatesNotInvalid(anyRateIsInvalid || snxRateInvalid);
        uint collateralForAccount = _collateral(account);
        uint amountToFixRatio =
            liquidations().calculateAmountToFixCollateral(debtBalance, _snxToUSD(collateralForAccount, snxRate));
        amountToLiquidate = amountToFixRatio < susdAmount ? amountToFixRatio : susdAmount;
        uint snxRedeemed = _usdToSnx(amountToLiquidate, snxRate);
        totalRedeemed = snxRedeemed.multiplyDecimal(SafeDecimalMath.unit().add(liquidationPenalty));
        if (totalRedeemed > collateralForAccount) {
            totalRedeemed = collateralForAccount;
            amountToLiquidate = _snxToUSD(
                collateralForAccount.divideDecimal(SafeDecimalMath.unit().add(liquidationPenalty)),
                snxRate
            );
        }
        _burnSynths(account, liquidator, amountToLiquidate, debtBalance, totalDebtIssued);
        if (amountToLiquidate == amountToFixRatio) {
            liquidations().removeAccountInLiquidation(account);
        }
    }
    function _requireRatesNotInvalid(bool anyRateIsInvalid) internal pure {
        require(!anyRateIsInvalid, "A synth or SNX rate is invalid");
    }
    function _requireCanIssueOnBehalf(address issueForAddress, address from) internal view {
        require(delegateApprovals().canIssueFor(issueForAddress, from), "Not approved to act on behalf");
    }
    function _requireCanBurnOnBehalf(address burnForAddress, address from) internal view {
        require(delegateApprovals().canBurnFor(burnForAddress, from), "Not approved to act on behalf");
    }
    function _issueSynths(
        address from,
        uint amount,
        bool issueMax
    ) internal {
        (uint maxIssuable, uint existingDebt, uint totalSystemDebt, bool anyRateIsInvalid) = _remainingIssuableSynths(from);
        _requireRatesNotInvalid(anyRateIsInvalid);
        if (!issueMax) {
            require(amount <= maxIssuable, "Amount too large");
        } else {
            amount = maxIssuable;
        }
        _addToDebtRegister(from, amount, existingDebt, totalSystemDebt);
        _setLastIssueEvent(from);
        synths[sUSD].issue(from, amount);
        debtCache().updateCachedsUSDDebt(int(amount));
        _appendAccountIssuanceRecord(from);
    }
    function _burnSynths(
        address debtAccount,
        address burnAccount,
        uint amount,
        uint existingDebt,
        uint totalDebtIssued
    ) internal returns (uint amountBurnt) {
        amountBurnt = existingDebt < amount ? existingDebt : amount;
        _removeFromDebtRegister(debtAccount, amountBurnt, existingDebt, totalDebtIssued);
        synths[sUSD].burn(burnAccount, amountBurnt);
        debtCache().updateCachedsUSDDebt(-int(amountBurnt));
        _appendAccountIssuanceRecord(debtAccount);
    }
    function _voluntaryBurnSynths(
        address from,
        uint amount,
        bool burnToTarget
    ) internal {
        if (!burnToTarget) {
            require(_canBurnSynths(from), "Minimum stake time not reached");
            (, uint refunded, uint numEntriesSettled) = exchanger().settle(from, sUSD);
            if (numEntriesSettled > 0) {
                amount = exchanger().calculateAmountAfterSettlement(from, sUSD, amount, refunded);
            }
        }
        (uint existingDebt, uint totalSystemValue, bool anyRateIsInvalid) = _debtBalanceOfAndTotalDebt(from, sUSD);
        (uint maxIssuableSynthsForAccount, bool snxRateInvalid) = _maxIssuableSynths(from);
        _requireRatesNotInvalid(anyRateIsInvalid || snxRateInvalid);
        require(existingDebt > 0, "No debt to forgive");
        if (burnToTarget) {
            amount = existingDebt.sub(maxIssuableSynthsForAccount);
        }
        uint amountBurnt = _burnSynths(from, from, amount, existingDebt, totalSystemValue);
        if (existingDebt.sub(amountBurnt) <= maxIssuableSynthsForAccount) {
            liquidations().removeAccountInLiquidation(from);
        }
    }
    function _setLastIssueEvent(address account) internal {
        flexibleStorage().setUIntValue(
            CONTRACT_NAME,
            keccak256(abi.encodePacked(LAST_ISSUE_EVENT, account)),
            block.timestamp
        );
    }
    function _appendAccountIssuanceRecord(address from) internal {
        uint initialDebtOwnership;
        uint debtEntryIndex;
        (initialDebtOwnership, debtEntryIndex) = synthetixState().issuanceData(from);
        feePool().appendAccountIssuanceRecord(from, initialDebtOwnership, debtEntryIndex);
    }
    function _addToDebtRegister(
        address from,
        uint amount,
        uint existingDebt,
        uint totalDebtIssued
    ) internal {
        ISynthetixState state = synthetixState();
        uint newTotalDebtIssued = amount.add(totalDebtIssued);
        uint debtPercentage = amount.divideDecimalRoundPrecise(newTotalDebtIssued);
        uint delta = SafeDecimalMath.preciseUnit().sub(debtPercentage);
        if (existingDebt > 0) {
            debtPercentage = amount.add(existingDebt).divideDecimalRoundPrecise(newTotalDebtIssued);
        } else {
            state.incrementTotalIssuerCount();
        }
        state.setCurrentIssuanceData(from, debtPercentage);
        if (state.debtLedgerLength() > 0) {
            state.appendDebtLedgerValue(state.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta));
        } else {
            state.appendDebtLedgerValue(SafeDecimalMath.preciseUnit());
        }
    }
    function _removeFromDebtRegister(
        address from,
        uint debtToRemove,
        uint existingDebt,
        uint totalDebtIssued
    ) internal {
        ISynthetixState state = synthetixState();
        uint newTotalDebtIssued = totalDebtIssued.sub(debtToRemove);
        uint delta = 0;
        if (newTotalDebtIssued > 0) {
            uint debtPercentage = debtToRemove.divideDecimalRoundPrecise(newTotalDebtIssued);
            delta = SafeDecimalMath.preciseUnit().add(debtPercentage);
        }
        if (debtToRemove == existingDebt) {
            state.setCurrentIssuanceData(from, 0);
            state.decrementTotalIssuerCount();
        } else {
            uint newDebt = existingDebt.sub(debtToRemove);
            uint newDebtPercentage = newDebt.divideDecimalRoundPrecise(newTotalDebtIssued);
            state.setCurrentIssuanceData(from, newDebtPercentage);
        }
        state.appendDebtLedgerValue(state.lastDebtLedgerEntry().multiplyDecimalRoundPrecise(delta));
    }
    function _onlySynthetix() internal view {
        require(msg.sender == address(synthetix()), "Issuer: Only the synthetix contract can perform this action");
    }
    modifier onlySynthetix() {
        _onlySynthetix();
        _;
    }
    function _onlySynthRedeemer() internal view {
        require(msg.sender == address(synthRedeemer()), "Issuer: Only the SynthRedeemer contract can perform this action");
    }
    modifier onlySynthRedeemer() {
        _onlySynthRedeemer();
        _;
    }
    event SynthAdded(bytes32 currencyKey, address synth);
    event SynthRemoved(bytes32 currencyKey, address synth);
}