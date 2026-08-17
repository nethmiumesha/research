pragma solidity ^0.5.16;
import "./Owned.sol";
import "./Proxyable.sol";
import "./LimitedSetup.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./interfaces/IFeePool.sol";
import "./SafeDecimalMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/ISynthetix.sol";
import "./FeePoolState.sol";
import "./FeePoolEternalStorage.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/ISynthetixState.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/IDelegateApprovals.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/ICollateralManager.sol";
import "./interfaces/IEtherWrapper.sol";
import "./interfaces/IFuturesMarketManager.sol";
contract FeePool is Owned, Proxyable, LimitedSetup, MixinSystemSettings, IFeePool {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    bytes32 public constant CONTRACT_NAME = "FeePool";
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;
    bytes32 private sUSD = "sUSD";
    struct FeePeriod {
        uint64 feePeriodId;
        uint64 startingDebtIndex;
        uint64 startTime;
        uint feesToDistribute;
        uint feesClaimed;
        uint rewardsToDistribute;
        uint rewardsClaimed;
    }
    uint8 public constant FEE_PERIOD_LENGTH = 2;
    FeePeriod[FEE_PERIOD_LENGTH] private _recentFeePeriods;
    uint256 private _currentFeePeriod;
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_FEEPOOLSTATE = "FeePoolState";
    bytes32 private constant CONTRACT_FEEPOOLETERNALSTORAGE = "FeePoolEternalStorage";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_SYNTHETIXSTATE = "SynthetixState";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_COLLATERALMANAGER = "CollateralManager";
    bytes32 private constant CONTRACT_REWARDSDISTRIBUTION = "RewardsDistribution";
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";
    bytes32 private constant LAST_FEE_WITHDRAWAL = "last_fee_withdrawal";
    constructor(
        address payable _proxy,
        address _owner,
        address _resolver
    ) public Owned(_owner) Proxyable(_proxy) LimitedSetup(3 weeks) MixinSystemSettings(_resolver) {
        _recentFeePeriodsStorage(0).feePeriodId = 1;
        _recentFeePeriodsStorage(0).startTime = uint64(now);
    }
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](13);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_SYNTHETIX;
        newAddresses[2] = CONTRACT_FEEPOOLSTATE;
        newAddresses[3] = CONTRACT_FEEPOOLETERNALSTORAGE;
        newAddresses[4] = CONTRACT_EXCHANGER;
        newAddresses[5] = CONTRACT_ISSUER;
        newAddresses[6] = CONTRACT_SYNTHETIXSTATE;
        newAddresses[7] = CONTRACT_REWARDESCROW_V2;
        newAddresses[8] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[9] = CONTRACT_REWARDSDISTRIBUTION;
        newAddresses[10] = CONTRACT_COLLATERALMANAGER;
        newAddresses[11] = CONTRACT_ETHER_WRAPPER;
        newAddresses[12] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }
    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }
    function feePoolState() internal view returns (FeePoolState) {
        return FeePoolState(requireAndGetAddress(CONTRACT_FEEPOOLSTATE));
    }
    function feePoolEternalStorage() internal view returns (FeePoolEternalStorage) {
        return FeePoolEternalStorage(requireAndGetAddress(CONTRACT_FEEPOOLETERNALSTORAGE));
    }
    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }
    function collateralManager() internal view returns (ICollateralManager) {
        return ICollateralManager(requireAndGetAddress(CONTRACT_COLLATERALMANAGER));
    }
    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }
    function synthetixState() internal view returns (ISynthetixState) {
        return ISynthetixState(requireAndGetAddress(CONTRACT_SYNTHETIXSTATE));
    }
    function rewardEscrowV2() internal view returns (IRewardEscrowV2) {
        return IRewardEscrowV2(requireAndGetAddress(CONTRACT_REWARDESCROW_V2));
    }
    function delegateApprovals() internal view returns (IDelegateApprovals) {
        return IDelegateApprovals(requireAndGetAddress(CONTRACT_DELEGATEAPPROVALS));
    }
    function rewardsDistribution() internal view returns (IRewardsDistribution) {
        return IRewardsDistribution(requireAndGetAddress(CONTRACT_REWARDSDISTRIBUTION));
    }
    function etherWrapper() internal view returns (IEtherWrapper) {
        return IEtherWrapper(requireAndGetAddress(CONTRACT_ETHER_WRAPPER));
    }
    function futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
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
    function recentFeePeriods(uint index)
        external
        view
        returns (
            uint64 feePeriodId,
            uint64 startingDebtIndex,
            uint64 startTime,
            uint feesToDistribute,
            uint feesClaimed,
            uint rewardsToDistribute,
            uint rewardsClaimed
        )
    {
        FeePeriod memory feePeriod = _recentFeePeriodsStorage(index);
        return (
            feePeriod.feePeriodId,
            feePeriod.startingDebtIndex,
            feePeriod.startTime,
            feePeriod.feesToDistribute,
            feePeriod.feesClaimed,
            feePeriod.rewardsToDistribute,
            feePeriod.rewardsClaimed
        );
    }
    function _recentFeePeriodsStorage(uint index) internal view returns (FeePeriod storage) {
        return _recentFeePeriods[(_currentFeePeriod + index) % FEE_PERIOD_LENGTH];
    }
    function appendAccountIssuanceRecord(
        address account,
        uint debtRatio,
        uint debtEntryIndex
    ) external onlyIssuerAndSynthetixState {
        feePoolState().appendAccountIssuanceRecord(
            account,
            debtRatio,
            debtEntryIndex,
            _recentFeePeriodsStorage(0).startingDebtIndex
        );
        emitIssuanceDebtRatioEntry(account, debtRatio, debtEntryIndex, _recentFeePeriodsStorage(0).startingDebtIndex);
    }
    function recordFeePaid(uint amount) external onlyInternalContracts {
        _recentFeePeriodsStorage(0).feesToDistribute = _recentFeePeriodsStorage(0).feesToDistribute.add(amount);
    }
    function setRewardsToDistribute(uint amount) external {
        address rewardsAuthority = address(rewardsDistribution());
        require(messageSender == rewardsAuthority || msg.sender == rewardsAuthority, "Caller is not rewardsAuthority");
        _recentFeePeriodsStorage(0).rewardsToDistribute = _recentFeePeriodsStorage(0).rewardsToDistribute.add(amount);
    }
    function closeCurrentFeePeriod() external issuanceActive {
        require(getFeePeriodDuration() > 0, "Fee Period Duration not set");
        require(_recentFeePeriodsStorage(0).startTime <= (now - getFeePeriodDuration()), "Too early to close fee period");
        etherWrapper().distributeFees();
        FeePeriod storage periodClosing = _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 2);
        FeePeriod storage periodToRollover = _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 1);
        _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 2).feesToDistribute = periodToRollover
            .feesToDistribute
            .sub(periodToRollover.feesClaimed)
            .add(periodClosing.feesToDistribute);
        _recentFeePeriodsStorage(FEE_PERIOD_LENGTH - 2).rewardsToDistribute = periodToRollover
            .rewardsToDistribute
            .sub(periodToRollover.rewardsClaimed)
            .add(periodClosing.rewardsToDistribute);
        _currentFeePeriod = _currentFeePeriod.add(FEE_PERIOD_LENGTH).sub(1).mod(FEE_PERIOD_LENGTH);
        delete _recentFeePeriods[_currentFeePeriod];
        _recentFeePeriodsStorage(0).feePeriodId = uint64(uint256(_recentFeePeriodsStorage(1).feePeriodId).add(1));
        _recentFeePeriodsStorage(0).startingDebtIndex = uint64(synthetixState().debtLedgerLength());
        _recentFeePeriodsStorage(0).startTime = uint64(now);
        emitFeePeriodClosed(_recentFeePeriodsStorage(1).feePeriodId);
    }
    function claimFees() external issuanceActive optionalProxy returns (bool) {
        return _claimFees(messageSender);
    }
    function claimOnBehalf(address claimingForAddress) external issuanceActive optionalProxy returns (bool) {
        require(delegateApprovals().canClaimFor(claimingForAddress, messageSender), "Not approved to claim on behalf");
        return _claimFees(claimingForAddress);
    }
    function _claimFees(address claimingAddress) internal returns (bool) {
        uint rewardsPaid = 0;
        uint feesPaid = 0;
        uint availableFees;
        uint availableRewards;
        (bool feesClaimable, bool anyRateIsInvalid) = _isFeesClaimableAndAnyRatesInvalid(claimingAddress);
        require(feesClaimable, "C-Ratio below penalty threshold");
        require(!anyRateIsInvalid, "A synth or SNX rate is invalid");
        (availableFees, availableRewards) = feesAvailable(claimingAddress);
        require(
            availableFees > 0 || availableRewards > 0,
            "No fees or rewards available for period, or fees already claimed"
        );
        _setLastFeeWithdrawal(claimingAddress, _recentFeePeriodsStorage(1).feePeriodId);
        if (availableFees > 0) {
            feesPaid = _recordFeePayment(availableFees);
            _payFees(claimingAddress, feesPaid);
        }
        if (availableRewards > 0) {
            rewardsPaid = _recordRewardPayment(availableRewards);
            _payRewards(claimingAddress, rewardsPaid);
        }
        emitFeesClaimed(claimingAddress, feesPaid, rewardsPaid);
        return true;
    }
    function importFeePeriod(
        uint feePeriodIndex,
        uint feePeriodId,
        uint startingDebtIndex,
        uint startTime,
        uint feesToDistribute,
        uint feesClaimed,
        uint rewardsToDistribute,
        uint rewardsClaimed
    ) public optionalProxy_onlyOwner onlyDuringSetup {
        require(startingDebtIndex <= synthetixState().debtLedgerLength(), "Cannot import bad data");
        _recentFeePeriods[_currentFeePeriod.add(feePeriodIndex).mod(FEE_PERIOD_LENGTH)] = FeePeriod({
            feePeriodId: uint64(feePeriodId),
            startingDebtIndex: uint64(startingDebtIndex),
            startTime: uint64(startTime),
            feesToDistribute: feesToDistribute,
            feesClaimed: feesClaimed,
            rewardsToDistribute: rewardsToDistribute,
            rewardsClaimed: rewardsClaimed
        });
    }
    function _recordFeePayment(uint sUSDAmount) internal returns (uint) {
        uint remainingToAllocate = sUSDAmount;
        uint feesPaid;
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint feesAlreadyClaimed = _recentFeePeriodsStorage(i).feesClaimed;
            uint delta = _recentFeePeriodsStorage(i).feesToDistribute.sub(feesAlreadyClaimed);
            if (delta > 0) {
                uint amountInPeriod = delta < remainingToAllocate ? delta : remainingToAllocate;
                _recentFeePeriodsStorage(i).feesClaimed = feesAlreadyClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                feesPaid = feesPaid.add(amountInPeriod);
                if (remainingToAllocate == 0) return feesPaid;
                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }
        return feesPaid;
    }
    function _recordRewardPayment(uint snxAmount) internal returns (uint) {
        uint remainingToAllocate = snxAmount;
        uint rewardPaid;
        for (uint i = FEE_PERIOD_LENGTH - 1; i < FEE_PERIOD_LENGTH; i--) {
            uint toDistribute =
                _recentFeePeriodsStorage(i).rewardsToDistribute.sub(_recentFeePeriodsStorage(i).rewardsClaimed);
            if (toDistribute > 0) {
                uint amountInPeriod = toDistribute < remainingToAllocate ? toDistribute : remainingToAllocate;
                _recentFeePeriodsStorage(i).rewardsClaimed = _recentFeePeriodsStorage(i).rewardsClaimed.add(amountInPeriod);
                remainingToAllocate = remainingToAllocate.sub(amountInPeriod);
                rewardPaid = rewardPaid.add(amountInPeriod);
                if (remainingToAllocate == 0) return rewardPaid;
                if (i == 0 && remainingToAllocate > 0) {
                    remainingToAllocate = 0;
                }
            }
        }
        return rewardPaid;
    }
    function _payFees(address account, uint sUSDAmount) internal notFeeAddress(account) {
        ISynth sUSDSynth = issuer().synths(sUSD);
        sUSDSynth.burn(FEE_ADDRESS, sUSDAmount);
        sUSDSynth.issue(account, sUSDAmount);
    }
    function _payRewards(address account, uint snxAmount) internal notFeeAddress(account) {
        uint escrowDuration = 52 weeks;
        rewardEscrowV2().appendVestingEntry(account, snxAmount, escrowDuration);
    }
    function totalFeesAvailable() external view returns (uint) {
        uint totalFees = 0;
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(_recentFeePeriodsStorage(i).feesToDistribute);
            totalFees = totalFees.sub(_recentFeePeriodsStorage(i).feesClaimed);
        }
        return totalFees;
    }
    function totalRewardsAvailable() external view returns (uint) {
        uint totalRewards = 0;
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalRewards = totalRewards.add(_recentFeePeriodsStorage(i).rewardsToDistribute);
            totalRewards = totalRewards.sub(_recentFeePeriodsStorage(i).rewardsClaimed);
        }
        return totalRewards;
    }
    function feesAvailable(address account) public view returns (uint, uint) {
        uint[2][FEE_PERIOD_LENGTH] memory userFees = feesByPeriod(account);
        uint totalFees = 0;
        uint totalRewards = 0;
        for (uint i = 1; i < FEE_PERIOD_LENGTH; i++) {
            totalFees = totalFees.add(userFees[i][0]);
            totalRewards = totalRewards.add(userFees[i][1]);
        }
        return (totalFees, totalRewards);
    }
    function _isFeesClaimableAndAnyRatesInvalid(address account) internal view returns (bool, bool) {
        (uint ratio, bool anyRateIsInvalid) = issuer().collateralisationRatioAndAnyRatesInvalid(account);
        uint targetRatio = getIssuanceRatio();
        if (ratio < targetRatio) {
            return (true, anyRateIsInvalid);
        }
        uint ratio_threshold = targetRatio.multiplyDecimal(SafeDecimalMath.unit().add(getTargetThreshold()));
        if (ratio > ratio_threshold) {
            return (false, anyRateIsInvalid);
        }
        return (true, anyRateIsInvalid);
    }
    function isFeesClaimable(address account) external view returns (bool feesClaimable) {
        (feesClaimable, ) = _isFeesClaimableAndAnyRatesInvalid(account);
    }
    function feesByPeriod(address account) public view returns (uint[2][FEE_PERIOD_LENGTH] memory results) {
        uint userOwnershipPercentage;
        uint debtEntryIndex;
        FeePoolState _feePoolState = feePoolState();
        (userOwnershipPercentage, debtEntryIndex) = _feePoolState.getAccountsDebtEntry(account, 0);
        if (debtEntryIndex == 0 && userOwnershipPercentage == 0) {
            uint[2][FEE_PERIOD_LENGTH] memory nullResults;
            return nullResults;
        }
        uint feesFromPeriod;
        uint rewardsFromPeriod;
        (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage, debtEntryIndex);
        results[0][0] = feesFromPeriod;
        results[0][1] = rewardsFromPeriod;
        uint lastFeeWithdrawal = getLastFeeWithdrawal(account);
        for (uint i = FEE_PERIOD_LENGTH - 1; i > 0; i--) {
            uint next = i - 1;
            uint nextPeriodStartingDebtIndex = _recentFeePeriodsStorage(next).startingDebtIndex;
            if (nextPeriodStartingDebtIndex > 0 && lastFeeWithdrawal < _recentFeePeriodsStorage(i).feePeriodId) {
                uint closingDebtIndex = uint256(nextPeriodStartingDebtIndex).sub(1);
                (userOwnershipPercentage, debtEntryIndex) = _feePoolState.applicableIssuanceData(account, closingDebtIndex);
                (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(i, userOwnershipPercentage, debtEntryIndex);
                results[i][0] = feesFromPeriod;
                results[i][1] = rewardsFromPeriod;
            }
        }
    }
    function _feesAndRewardsFromPeriod(
        uint period,
        uint ownershipPercentage,
        uint debtEntryIndex
    ) internal view returns (uint, uint) {
        if (ownershipPercentage == 0) return (0, 0);
        uint debtOwnershipForPeriod = ownershipPercentage;
        if (period > 0) {
            uint closingDebtIndex = uint256(_recentFeePeriodsStorage(period - 1).startingDebtIndex).sub(1);
            debtOwnershipForPeriod = _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
        }
        uint feesFromPeriod = _recentFeePeriodsStorage(period).feesToDistribute.multiplyDecimal(debtOwnershipForPeriod);
        uint rewardsFromPeriod =
            _recentFeePeriodsStorage(period).rewardsToDistribute.multiplyDecimal(debtOwnershipForPeriod);
        return (feesFromPeriod.preciseDecimalToDecimal(), rewardsFromPeriod.preciseDecimalToDecimal());
    }
    function _effectiveDebtRatioForPeriod(
        uint closingDebtIndex,
        uint ownershipPercentage,
        uint debtEntryIndex
    ) internal view returns (uint) {
        ISynthetixState _synthetixState = synthetixState();
        uint feePeriodDebtOwnership =
            _synthetixState
                .debtLedger(closingDebtIndex)
                .divideDecimalRoundPrecise(_synthetixState.debtLedger(debtEntryIndex))
                .multiplyDecimalRoundPrecise(ownershipPercentage);
        return feePeriodDebtOwnership;
    }
    function effectiveDebtRatioForPeriod(address account, uint period) external view returns (uint) {
        require(period != 0, "Current period is not closed yet");
        require(period < FEE_PERIOD_LENGTH, "Exceeds the FEE_PERIOD_LENGTH");
        if (_recentFeePeriodsStorage(period - 1).startingDebtIndex == 0) return 0;
        uint closingDebtIndex = uint256(_recentFeePeriodsStorage(period - 1).startingDebtIndex).sub(1);
        uint ownershipPercentage;
        uint debtEntryIndex;
        (ownershipPercentage, debtEntryIndex) = feePoolState().applicableIssuanceData(account, closingDebtIndex);
        return _effectiveDebtRatioForPeriod(closingDebtIndex, ownershipPercentage, debtEntryIndex);
    }
    function getLastFeeWithdrawal(address _claimingAddress) public view returns (uint) {
        return feePoolEternalStorage().getUIntValue(keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)));
    }
    function getPenaltyThresholdRatio() public view returns (uint) {
        return getIssuanceRatio().multiplyDecimal(SafeDecimalMath.unit().add(getTargetThreshold()));
    }
    function _setLastFeeWithdrawal(address _claimingAddress, uint _feePeriodID) internal {
        feePoolEternalStorage().setUIntValue(
            keccak256(abi.encodePacked(LAST_FEE_WITHDRAWAL, _claimingAddress)),
            _feePeriodID
        );
    }
    function _isInternalContract(address account) internal view returns (bool) {
        return
            account == address(exchanger()) ||
            issuer().synthsByAddress(account) != bytes32(0) ||
            collateralManager().hasCollateral(account) ||
            account == address(etherWrapper()) ||
            account == address(futuresMarketManager());
    }
    modifier onlyInternalContracts {
        require(_isInternalContract(msg.sender), "Only Internal Contracts");
        _;
    }
    modifier onlyIssuerAndSynthetixState {
        bool isIssuer = msg.sender == address(issuer());
        bool isSynthetixState = msg.sender == address(synthetixState());
        require(isIssuer || isSynthetixState, "Issuer and SynthetixState only");
        _;
    }
    modifier notFeeAddress(address account) {
        require(account != FEE_ADDRESS, "Fee address not allowed");
        _;
    }
    modifier issuanceActive() {
        systemStatus().requireIssuanceActive();
        _;
    }
    event IssuanceDebtRatioEntry(
        address indexed account,
        uint debtRatio,
        uint debtEntryIndex,
        uint feePeriodStartingDebtIndex
    );
    bytes32 private constant ISSUANCEDEBTRATIOENTRY_SIG =
        keccak256("IssuanceDebtRatioEntry(address,uint256,uint256,uint256)");
    function emitIssuanceDebtRatioEntry(
        address account,
        uint debtRatio,
        uint debtEntryIndex,
        uint feePeriodStartingDebtIndex
    ) internal {
        proxy._emit(
            abi.encode(debtRatio, debtEntryIndex, feePeriodStartingDebtIndex),
            2,
            ISSUANCEDEBTRATIOENTRY_SIG,
            bytes32(uint256(uint160(account))),
            0,
            0
        );
    }
    event FeePeriodClosed(uint feePeriodId);
    bytes32 private constant FEEPERIODCLOSED_SIG = keccak256("FeePeriodClosed(uint256)");
    function emitFeePeriodClosed(uint feePeriodId) internal {
        proxy._emit(abi.encode(feePeriodId), 1, FEEPERIODCLOSED_SIG, 0, 0, 0);
    }
    event FeesClaimed(address account, uint sUSDAmount, uint snxRewards);
    bytes32 private constant FEESCLAIMED_SIG = keccak256("FeesClaimed(address,uint256,uint256)");
    function emitFeesClaimed(
        address account,
        uint sUSDAmount,
        uint snxRewards
    ) internal {
        proxy._emit(abi.encode(account, sUSDAmount, snxRewards), 1, FEESCLAIMED_SIG, 0, 0, 0);
    }
}