pragma solidity >=0.8.29 <0.9.0;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { BaseCooldownStrategy } from "@superearn/core/strategy/BaseCooldownStrategy.sol";
contract StrategyMorphoV2Vault is BaseCooldownStrategy {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    error RedeemAmountMismatch();
    uint256 private immutable MAX_SUPPLY_THRESHOLD;
    IERC4626 public immutable morphoVaultV2;
    uint256 private immutable oneUnderlying;
    uint256 private immutable oneShare;
    uint256 private lastRedeemIndex;
    mapping(uint256 => uint256) public redeemAmounts;
    constructor(
        address _vault,
        address _morphoVaultV2
    )
        BaseCooldownStrategy(_vault, _morphoVaultV2, IERC4626(_morphoVaultV2).asset())
    {
        morphoVaultV2 = IERC4626(_morphoVaultV2);
        AMOUNT_TO_SHARE_BUFFER = 0;
        minReportDelay = 0;
        maxReportDelay = 7 days;
        oneShare = 10 ** IERC20Metadata(_morphoVaultV2).decimals();
        oneUnderlying = 10 ** IERC20Metadata(IERC4626(_morphoVaultV2).asset()).decimals();
        MAX_SUPPLY_THRESHOLD = 1_000_000_000 * oneUnderlying;
    }
    function name() external view override returns (string memory) {
        return string.concat("StrategyMorphoV2Vault ", IERC20Metadata(address(morphoVaultV2)).name());
    }
    function getCooldownPeriod() public view virtual override returns (uint256 cooldownPeriod) {
        cooldownPeriod = 0;
    }
    function requestDeposit(uint256 assets)
        internal
        virtual
        override
        returns (bool success, uint256 shares, uint256 filledAssets)
    {
        if (!beforeExternalDeposit(assets)) return (false, 0, 0);
        uint256 beforeUnderlyingBalance = externalUnderlyingToken.balanceOf(address(this));
        uint256 beforeShareBalance = externalShareToken.balanceOf(address(this));
        externalUnderlyingToken.forceApprove(address(morphoVaultV2), assets);
        try morphoVaultV2.deposit(assets, address(this)) {
            success = true;
            shares = externalShareToken.balanceOf(address(this)) - beforeShareBalance;
            filledAssets = beforeUnderlyingBalance - externalUnderlyingToken.balanceOf(address(this));
        } catch {
            success = false;
        }
    }
    function requestRedeem(uint256 shares)
        internal
        virtual
        override
        returns (bool success, uint256 redeemId, uint256 redeemUnderlyingAmount, uint256 cooldownPeriod)
    {
        if (!beforeExternalRedeem(shares)) return (false, 0, 0, 0);
        uint256 balanceDelta = externalUnderlyingToken.balanceOf(address(this));
        try morphoVaultV2.redeem(shares, address(this), address(this)) returns (uint256 redeemAmount) {
            success = true;
            redeemAmounts[++lastRedeemIndex] = redeemAmount;
            (redeemId,,, redeemUnderlyingAmount,) = getRedeemDetail(getLastRedeemIndex());
            balanceDelta = externalUnderlyingToken.balanceOf(address(this)) - balanceDelta;
            if (balanceDelta != redeemAmount) {
                revert RedeemAmountMismatch();
            }
        } catch {
            success = false;
        }
        cooldownPeriod = getCooldownPeriod();
    }
    function requestClaim(uint256  ) internal virtual override returns (bool, uint256) {
        assert(false);
    }
    function previewDeposit(uint256 assets) public view virtual override returns (uint256 shares) {
        return morphoVaultV2.previewDeposit(assets);
    }
    function previewMint(uint256 shares) public view virtual override returns (uint256 assets) {
        return morphoVaultV2.previewMint(shares);
    }
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256 shares) {
        return morphoVaultV2.previewWithdraw(assets);
    }
    function previewRedeem(uint256 shares) public view virtual override returns (uint256 assets) {
        return morphoVaultV2.previewRedeem(shares);
    }
    function getLastRedeemIndex() internal view virtual override returns (uint256) {
        return lastRedeemIndex;
    }
    function getRedeemDetail(uint256 redeemIndex)
        public
        view
        virtual
        override
        returns (
            uint256 redeemId,
            uint256 redeemTimestamp,
            address redeemUser,
            uint256 redeemUnderlyingAmount,
            bool redeemIsDone
        )
    {
        redeemId = redeemIndex;
        redeemUser = address(this);
        redeemUnderlyingAmount = redeemAmounts[redeemId];
        redeemIsDone = redeemId > 0;
    }
    function getSupplyCap() public view virtual override returns (uint256 supplyAssetsCap, uint256 availableAssets) {
        supplyAssetsCap = MAX_SUPPLY_THRESHOLD;
        availableAssets = MAX_SUPPLY_THRESHOLD;
    }
    function isPredepositAlreadyClaimed(uint256 predepositId) external view virtual override returns (bool isClaimed) {
        uint256 redeemIndex = externalRedeemIndexes[predepositId];
        if (redeemIndex == 0) return false;
        (,,,, isClaimed) = getRedeemDetail(redeemIndex);
    }
    function predepositDebtRetrievable(uint256 predepositId)
        external
        view
        virtual
        override
        returns (bool isRetrievable)
    {
        isRetrievable = false;
    }
    function ethToWant(uint256  ) public view virtual override returns (uint256) {
        return 0;
    }
    function beforeExternalDeposit(uint256 assets) internal view virtual override returns (bool valid) {
        valid = morphoVaultV2.previewDeposit(assets) > 0;
    }
    function beforeExternalRedeem(uint256 shares) internal view virtual override returns (bool valid) {
        valid = morphoVaultV2.previewRedeem(shares) > 0;
    }
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt = getStrategyParams().totalDebt;
        _debtPayment = Math.min(_debtOutstanding, totalAssets);
        totalAssets -= _debtPayment;
        totalDebt -= _debtPayment;
        if (totalAssets > totalDebt) {
            _profit = totalAssets - totalDebt;
        } else {
            _loss = totalDebt - totalAssets;
        }
        (uint256 toReturn,) = liquidatePosition(_profit + _debtPayment);
        totalAssets = estimatedTotalAssets();
        totalDebt = getStrategyParams().totalDebt;
        _debtPayment = Math.min(_debtPayment, toReturn);
        totalAssets = totalAssets > _debtPayment ? totalAssets - _debtPayment : 0;
        totalDebt = totalDebt > _debtPayment ? totalDebt - _debtPayment : 0;
        if (totalAssets > totalDebt) {
            _profit = Math.min(toReturn - _debtPayment, totalAssets - totalDebt);
            _loss = 0;
        } else {
            _profit = 0;
            _loss = totalDebt - totalAssets;
        }
    }
    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        override
        nonReentrant
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        _redepositUnderlyingSurplus();
        uint256 pendingInvested = want.balanceOf(address(this));
        if (pendingInvested >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        (,, uint256 lossShares) = premintCooldownVault(_amountNeeded - pendingInvested);
        uint256 available = want.balanceOf(address(this));
        if (_amountNeeded > available) {
            _liquidatedAmount = available;
            _loss = Math.min(_amountNeeded - available, lossShares);
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }
    function liquidateAllPositions() internal virtual override nonReentrant returns (uint256 _amountFreed) {
        _redepositUnderlyingSurplus();
        premintCooldownVault(estimatedTotalAssets() + oneUnderlying);
        uint256 gross = want.balanceOf(address(this));
        _amountFreed = remainingPredepositDebt >= gross ? 0 : gross - remainingPredepositDebt;
    }
    function adjustPosition(uint256 _debtOutstanding) internal virtual override nonReentrant {
        if (emergencyExit) return;
        uint256 pendingInvested = want.balanceOf(address(this));
        if (_debtOutstanding >= pendingInvested) return;
        uint256 toInvestShares;
        unchecked {
            uint256 _free = cooldownVault.maxInstantRedeem(address(this));
            uint256 _maxInvest = pendingInvested - _debtOutstanding;
            toInvestShares = Math.min(_free, _maxInvest);
            (, uint256 _availableUnderlying) = getSupplyCap();
            toInvestShares = Math.min(toInvestShares, cooldownVault.previewDeposit(_availableUnderlying));
        }
        uint256 toInvestAssets = cooldownVault.instantRedeem(toInvestShares);
        if (remainingPredepositDebt > shortfallTolerance) {
            toInvestAssets = 0;
        }
        (,, uint256 filledAssets) = requestDeposit(toInvestAssets);
        uint256 unfilledAssets = toInvestAssets - filledAssets;
        if (unfilledAssets > 0) {
            externalUnderlyingToken.forceApprove(address(cooldownVault), unfilledAssets);
            cooldownVault.deposit(unfilledAssets, address(this));
        }
        emit AdjustPosition(this.getUtilizationRate(), filledAssets, unfilledAssets, estimatedTotalAssets());
    }
    function prepareMigration(address _newStrategy) internal virtual override {
        _requireNoOutstandingDebt();
        externalShareToken.safeTransfer(_newStrategy, externalShareToken.balanceOf(address(this)));
        externalUnderlyingToken.safeTransfer(_newStrategy, externalUnderlyingToken.balanceOf(address(this)));
    }
    function protectedTokens() internal view virtual override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(externalShareToken);
        protected[1] = address(externalUnderlyingToken);
        return protected;
    }
    function tendTrigger(uint256  ) public view virtual override returns (bool) {
        if (emergencyExit) return false;
        uint256 pendingInvested = want.balanceOf(address(this));
        if (pendingInvested == 0) return false;
        uint256 idleBalance = cooldownVault.idleBalance();
        return beforeExternalDeposit(Math.min(idleBalance, pendingInvested));
    }
    function harvestTrigger(uint256 callCostInWei) public view virtual override returns (bool) {
        bool trigger = super.harvestTrigger(callCostInWei);
        uint256 lastReport = getStrategyParams().lastReport;
        if (trigger) {
            if (forceHarvestTriggerOnce) return true;
            if ((block.timestamp - lastReport) >= maxReportDelay) return true;
        } else {
            return false;
        }
        if (block.timestamp == lastReport) return false;
        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt = getStrategyParams().totalDebt;
        uint256 credit = vault.creditAvailable();
        uint256 _debtPayment = 0;
        uint256 _debtOutstanding = vault.debtOutstanding();
        if (totalAssets > _debtOutstanding) {
            _debtPayment = _debtOutstanding;
        } else {
            _debtPayment = totalAssets;
        }
        totalAssets -= _debtPayment;
        totalDebt -= _debtPayment;
        uint256 _profit = 0;
        if (totalAssets > totalDebt) {
            _profit = totalAssets - totalDebt;
        }
        uint256 halfCreditThreshold = creditThreshold >> 1;
        uint256 totalAvail = _debtPayment + _profit;
        if (totalAvail < credit) {
            return (credit - totalAvail) >= halfCreditThreshold;
        } else if (totalAvail > credit) {
            return (totalAvail - credit) >= halfCreditThreshold;
        }
        return false;
    }
}