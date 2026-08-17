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
import "./interfaces/ISynthetixDebtShare.sol";
import "./FeePoolEternalStorage.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/IRewardEscrowV2.sol";
import "./interfaces/IDelegateApprovals.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/ICollateralManager.sol";
import "./interfaces/IEtherWrapper.sol";
import "./interfaces/IWrapperFactory.sol";
contract FeePool is Owned, Proxyable, LimitedSetup, MixinSystemSettings, IFeePool {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    bytes32 public constant CONTRACT_NAME = "FeePool";
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;
    bytes32 private sUSD = "sUSD";
    struct FeePeriod {
        uint64 feePeriodId;
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
    bytes32 private constant CONTRACT_SYNTHETIXDEBTSHARE = "SynthetixDebtShare";
    bytes32 private constant CONTRACT_FEEPOOLETERNALSTORAGE = "FeePoolEternalStorage";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_REWARDESCROW_V2 = "RewardEscrowV2";
    bytes32 private constant CONTRACT_DELEGATEAPPROVALS = "DelegateApprovals";
    bytes32 private constant CONTRACT_COLLATERALMANAGER = "CollateralManager";
    bytes32 private constant CONTRACT_REWARDSDISTRIBUTION = "RewardsDistribution";
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_WRAPPER_FACTORY = "WrapperFactory";
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
        bytes32[] memory newAddresses = new bytes32[](12);
        newAddresses[0] = CONTRACT_SYSTEMSTATUS;
        newAddresses[1] = CONTRACT_SYNTHETIX;
        newAddresses[2] = CONTRACT_SYNTHETIXDEBTSHARE;
        newAddresses[3] = CONTRACT_FEEPOOLETERNALSTORAGE;
        newAddresses[4] = CONTRACT_EXCHANGER;
        newAddresses[5] = CONTRACT_ISSUER;
        newAddresses[6] = CONTRACT_REWARDESCROW_V2;
        newAddresses[7] = CONTRACT_DELEGATEAPPROVALS;
        newAddresses[8] = CONTRACT_REWARDSDISTRIBUTION;
        newAddresses[9] = CONTRACT_COLLATERALMANAGER;
        newAddresses[10] = CONTRACT_WRAPPER_FACTORY;
        newAddresses[11] = CONTRACT_ETHER_WRAPPER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }
    function synthetix() internal view returns (ISynthetix) {
        return ISynthetix(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }
    function synthetixDebtShare() internal view returns (ISynthetixDebtShare) {
        return ISynthetixDebtShare(requireAndGetAddress(CONTRACT_SYNTHETIXDEBTSHARE));
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
    function wrapperFactory() internal view returns (IWrapperFactory) {
        return IWrapperFactory(requireAndGetAddress(CONTRACT_WRAPPER_FACTORY));
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
            uint64 unused,
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
            0,
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
    function recordFeePaid(uint amount) external onlyInternalContracts {
        _recentFeePeriodsStorage(0).feesToDistribute = _recentFeePeriodsStorage(0).feesToDistribute.add(amount);
    }
    function setRewardsToDistribute(uint amount) external optionalProxy {
        require(messageSender == address(rewardsDistribution()), "RewardsDistribution only");
        _recentFeePeriodsStorage(0).rewardsToDistribute = _recentFeePeriodsStorage(0).rewardsToDistribute.add(amount);
    }
    function closeCurrentFeePeriod() external issuanceActive {
        require(getFeePeriodDuration() > 0, "Fee Period Duration not set");
        require(_recentFeePeriodsStorage(0).startTime <= (now - getFeePeriodDuration()), "Too early to close fee period");
        etherWrapper().distributeFees();
        wrapperFactory().distributeFees();
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
        uint newFeePeriodId = uint256(_recentFeePeriodsStorage(1).feePeriodId).add(1);
        _recentFeePeriodsStorage(0).feePeriodId = uint64(newFeePeriodId);
        _recentFeePeriodsStorage(0).startTime = uint64(now);
        issuer().setCurrentPeriodId(uint128(newFeePeriodId));
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
        uint startTime,
        uint feesToDistribute,
        uint feesClaimed,
        uint rewardsToDistribute,
        uint rewardsClaimed
    ) external optionalProxy_onlyOwner onlyDuringSetup {
        _recentFeePeriods[_currentFeePeriod.add(feePeriodIndex).mod(FEE_PERIOD_LENGTH)] = FeePeriod({
            feePeriodId: uint64(feePeriodId),
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
        ISynthetixDebtShare _debtShare = synthetixDebtShare();
        userOwnershipPercentage = _debtShare.sharePercent(account);
        if (userOwnershipPercentage == 0) {
            uint[2][FEE_PERIOD_LENGTH] memory nullResults;
            return nullResults;
        }
        uint feesFromPeriod;
        uint rewardsFromPeriod;
        (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(0, userOwnershipPercentage);
        results[0][0] = feesFromPeriod;
        results[0][1] = rewardsFromPeriod;
        uint lastFeeWithdrawal = getLastFeeWithdrawal(account);
        for (uint i = FEE_PERIOD_LENGTH - 1; i > 0; i--) {
            uint64 periodId = _recentFeePeriodsStorage(i).feePeriodId;
            if (lastFeeWithdrawal < periodId) {
                userOwnershipPercentage = _debtShare.sharePercentOnPeriod(account, uint(periodId));
                (feesFromPeriod, rewardsFromPeriod) = _feesAndRewardsFromPeriod(i, userOwnershipPercentage);
                results[i][0] = feesFromPeriod;
                results[i][1] = rewardsFromPeriod;
            }
        }
    }
    function _feesAndRewardsFromPeriod(
        uint period,
        uint ownershipPercentage
    ) internal view returns (uint, uint) {
        if (ownershipPercentage == 0) return (0, 0);
        uint feesFromPeriod = _recentFeePeriodsStorage(period).feesToDistribute.multiplyDecimal(ownershipPercentage);
        uint rewardsFromPeriod =
            _recentFeePeriodsStorage(period).rewardsToDistribute.multiplyDecimal(ownershipPercentage);
        return (feesFromPeriod, rewardsFromPeriod);
    }
    function effectiveDebtRatioForPeriod(address account, uint period) external view returns (uint) {
        require(period != 0, "Current period is not closed yet");
        require(period < FEE_PERIOD_LENGTH, "Exceeds the FEE_PERIOD_LENGTH");
        if (_recentFeePeriodsStorage(period - 1).startTime == 0) return 0;
        return synthetixDebtShare().sharePercentOnPeriod(account, uint(_recentFeePeriods[period].feePeriodId));
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
    modifier onlyInternalContracts {
        bool isExchanger = msg.sender == address(exchanger());
        bool isSynth = issuer().synthsByAddress(msg.sender) != bytes32(0);
        bool isCollateral = collateralManager().hasCollateral(msg.sender);
        bool isEtherWrapper = msg.sender == address(etherWrapper());
        bool isWrapper = msg.sender == address(wrapperFactory());
        require(isExchanger || isSynth || isCollateral || isEtherWrapper || isWrapper, "Only Internal Contracts");
        _;
    }
    modifier onlyIssuer {
        bool isIssuer = msg.sender == address(issuer());
        require(isIssuer, "Issuer only");
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