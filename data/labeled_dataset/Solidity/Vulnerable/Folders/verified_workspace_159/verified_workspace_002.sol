pragma solidity >=0.8.29 <0.9.0;
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICooldownVault } from "@superearn/interface/ICooldownVault.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { StrategyParams } from "@superearn/interface/IVault.sol";
import { BaseStrategy } from "@yearn-vaults/BaseStrategy.sol";
import { IStrategyCooldownAware } from "@superearn/interface/IStrategyCooldownAware.sol";
import { TimelockExecutionLib } from "@superearn/core/lib/TimelockExecutionLib.sol";
abstract contract BaseCooldownStrategy is IStrategyCooldownAware, BaseStrategy, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using TimelockExecutionLib for TimelockExecutionLib.TimelockStorage;
    error InvalidExternalToken();
    error OnlyCooldownVault();
    error InvalidExternalRedeem();
    error InvalidDebtClaimState();
    error CannotRepayByFailedClaim();
    error ClaimAlreadyProcessed();
    error InsufficientUnderlyingBalance(uint256 requested, uint256 available);
    error ZeroAssets();
    error RepayAmountExceedsShortfall(uint256 requested, uint256 outstanding);
    error OutstandingPredepositDebt();
    uint256 private constant BASIS_POINTS = 10_000;
    uint256 internal immutable AMOUNT_TO_SHARE_BUFFER;
    modifier onlyCooldownVault() {
        if (msg.sender != address(cooldownVault)) revert OnlyCooldownVault();
        _;
    }
    mapping(uint256 predepositId => uint256 externalRedeemIndex) public externalRedeemIndexes;
    IERC20 public immutable externalShareToken;
    IERC20 public immutable externalUnderlyingToken;
    ICooldownVault public immutable cooldownVault;
    uint256 public shortfallTolerance;
    TimelockExecutionLib.TimelockStorage internal _timelockStorage;
    uint256 public remainingPredepositDebt;
    constructor(address _vault, address _externalShareToken, address _externalUnderlyingToken) BaseStrategy(_vault) {
        if (_externalShareToken == address(0)) revert InvalidExternalToken();
        externalShareToken = IERC20(_externalShareToken);
        externalUnderlyingToken = IERC20(_externalUnderlyingToken);
        cooldownVault = ICooldownVault(address(want));
        if (_externalUnderlyingToken != cooldownVault.asset()) {
            revert InvalidExternalToken();
        }
        shortfallTolerance = 100 * 10 ** IERC20Metadata(address(want)).decimals();
        _timelockStorage.timelockDelay = 0 days;
    }
    function getCooldownPeriod() public view virtual override returns (uint256 cooldownPeriod);
    function requestDeposit(uint256 assets)
        internal
        virtual
        returns (bool success, uint256 shares, uint256 filledAssets)
    {
        if (!beforeExternalDeposit(assets)) return (false, 0, 0);
    }
    function requestRedeem(uint256 shares)
        internal
        virtual
        returns (bool success, uint256 redeemId, uint256 redeemUnderlyingAmount, uint256 cooldownPeriod)
    {
        if (!beforeExternalRedeem(shares)) return (false, 0, 0, 0);
    }
    function requestClaim(uint256 redeemIndex) internal virtual returns (bool success, uint256 claimedAmount);
    function previewDeposit(uint256 assets) public view virtual override returns (uint256 shares);
    function previewMint(uint256 shares) public view virtual override returns (uint256 assets);
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256 shares);
    function previewRedeem(uint256 shares) public view virtual override returns (uint256 assets);
    function getLastRedeemIndex() internal view virtual returns (uint256);
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
        );
    function getSupplyCap() public view virtual override returns (uint256 supplyAssetsCap, uint256 availableAssets);
    function isPredepositAlreadyClaimed(uint256 predepositId) external view virtual override returns (bool isClaimed);
    function predepositDebtRetrievable(uint256 predepositId)
        external
        view
        virtual
        override
        returns (bool isRetrievable);
    function beforeExternalDeposit(uint256 assets) internal view virtual returns (bool valid);
    function beforeExternalRedeem(uint256 shares) internal view virtual returns (bool valid);
    function premintCooldownVault(uint256 sharesNeeded)
        internal
        virtual
        returns (uint256 predepositId, uint256 preShares, uint256 lossShares)
    {
        bool redeemSuccess;
        uint256 redeemIndex;
        uint256 redeemUsdt;
        uint256 cooldownPeriod;
        {
            uint256 _needUsdt = cooldownVault.previewMint(sharesNeeded);
            uint256 _needSusdt = previewWithdraw(_needUsdt + AMOUNT_TO_SHARE_BUFFER);
            uint256 _susdtBalance = externalShareToken.balanceOf(address(this));
            uint256 shares = Math.min(_needSusdt, _susdtBalance);
            (redeemSuccess, redeemIndex, redeemUsdt, cooldownPeriod) = requestRedeem(shares);
            if (!redeemSuccess) return (0, 0, 0);
        }
        if (!emergencyExit && redeemIndex == 0) revert InvalidExternalRedeem();
        if (cooldownPeriod == 0) {
            externalUnderlyingToken.forceApprove(address(cooldownVault), redeemUsdt);
            preShares = cooldownVault.deposit(redeemUsdt, address(this));
            lossShares = sharesNeeded > preShares ? (sharesNeeded - preShares) : 0;
            return (0, preShares, lossShares);
        }
        (predepositId, preShares) = cooldownVault.predeposit(redeemUsdt);
        if (predepositId == 0) return (0, 0, 0);
        lossShares = sharesNeeded > preShares ? (sharesNeeded - preShares) : 0;
        externalRedeemIndexes[predepositId] = redeemIndex;
        emit Preminted(predepositId, redeemUsdt, preShares, redeemIndex);
    }
    function repayPredepositDebt(uint256 predepositId)
        external
        virtual
        override
        onlyCooldownVault
        nonReentrant
        returns (uint256 repayAmount)
    {
        (,, uint256 predepositDebt,,, bool predepositRepaymentFinished) = cooldownVault.predepositRequests(predepositId);
        if (predepositRepaymentFinished) {
            revert InvalidDebtClaimState();
        }
        uint256 redeemIndex = externalRedeemIndexes[predepositId];
        (,,,, bool redeemIsDone) = getRedeemDetail(redeemIndex);
        if (redeemIsDone) revert ClaimAlreadyProcessed();
        (bool claimSuccess, uint256 claimedAmount) = requestClaim(redeemIndex);
        if (!claimSuccess) revert CannotRepayByFailedClaim();
        if (claimedAmount < predepositDebt) {
            repayAmount = claimedAmount;
            remainingPredepositDebt += predepositDebt - claimedAmount;
        } else {
            repayAmount = predepositDebt;
        }
        externalUnderlyingToken.safeTransfer(msg.sender, repayAmount);
        emit PredepositDebtRepaid(predepositId, repayAmount);
    }
    function repayRemainingPredepositDebt(uint256 repayAmount) internal virtual {
        uint256 balance = externalUnderlyingToken.balanceOf(address(this));
        if (repayAmount == 0) revert ZeroAssets();
        if (repayAmount > remainingPredepositDebt) {
            revert RepayAmountExceedsShortfall(repayAmount, remainingPredepositDebt);
        }
        if (repayAmount > balance) {
            revert InsufficientUnderlyingBalance(repayAmount, balance);
        }
        externalUnderlyingToken.safeIncreaseAllowance(address(cooldownVault), repayAmount);
        cooldownVault.retrieveShortfall(repayAmount);
        remainingPredepositDebt -= repayAmount;
        emit RemainingPredepositDebtRepaid(repayAmount);
    }
    function _redepositUnderlyingSurplus() internal virtual {
        uint256 underlyingBal = externalUnderlyingToken.balanceOf(address(this));
        if (underlyingBal == 0) return;
        uint256 reserve = cooldownVault.strategyDebtOutstanding(address(this));
        if (underlyingBal <= reserve) return;
        uint256 surplus = underlyingBal - reserve;
        externalUnderlyingToken.forceApprove(address(cooldownVault), surplus);
        cooldownVault.deposit(surplus, address(this));
    }
    function emergencyRedeem(uint256 shares)
        external
        virtual
        override
        onlyGovernance
        returns (bool success, uint256 redeemId, uint256 redeemUnderlyingAmount, uint256 cooldownPeriod)
    {
        return requestRedeem(shares);
    }
    function emergencyClaim(uint256 redeemIndex)
        external
        virtual
        override
        onlyGovernance
        returns (bool success, uint256 claimedAmount)
    {
        return requestClaim(redeemIndex);
    }
    function emergencyRepayRemainingPredepositDebt(uint256 repayAmount) external virtual onlyGovernance {
        repayRemainingPredepositDebt(repayAmount);
    }
    function setShortfallTolerance(uint256 newTolerance) external virtual onlyGovernance {
        uint256 oldTolerance = shortfallTolerance;
        shortfallTolerance = newTolerance;
        emit ShortfallToleranceUpdated(oldTolerance, newTolerance);
    }
    function submitExecution(
        address[] calldata targets,
        bytes[] calldata calldatas
    )
        external
        virtual
        override
        onlyGovernance
    {
        bytes4[] memory allowedSelfCallSelectors = new bytes4[](1);
        allowedSelfCallSelectors[0] = this._setTimelockDelay.selector;
        _timelockStorage.submitExecution(targets, calldatas, allowedSelfCallSelectors);
    }
    function acceptExecution()
        external
        virtual
        override
        onlyGovernance
        returns (bool success, bytes memory returnData)
    {
        return _timelockStorage.acceptExecution();
    }
    function cancelExecution() external virtual override onlyAuthorized {
        _timelockStorage.cancelExecution();
    }
    function setAllowedTarget(address target, bool allowed) external virtual override onlyGovernance {
        _timelockStorage.setAllowedTarget(target, allowed);
    }
    function _setTimelockDelay(uint256 newDelay) external virtual {
        if (msg.sender != address(this)) {
            revert TimelockExecutionLib.InvalidExecutionState("ONLY_SELF");
        }
        _timelockStorage.setTimelockDelay(newDelay);
    }
    function pendingExecution() external view returns (TimelockExecutionLib.PendingExecution memory) {
        return _timelockStorage.pendingExecution;
    }
    function allowedTargets(address target) external view returns (bool) {
        return _timelockStorage.allowedTargets[target];
    }
    function timelockDelay() external view returns (uint256) {
        return _timelockStorage.timelockDelay;
    }
    function getUtilizationRate() external view virtual override returns (uint256) {
        uint256 totalAssets = estimatedTotalAssets();
        uint256 pendingInvested = want.balanceOf(address(this));
        if (totalAssets == 0) return 0;
        return Math.mulDiv(totalAssets - pendingInvested, BASIS_POINTS, totalAssets);
    }
    function getStrategyParams() internal view virtual returns (StrategyParams memory) {
        return vault.strategies(address(this));
    }
    function estimatedTotalAssets() public view virtual override returns (uint256) {
        uint256 pendingInvested = want.balanceOf(address(this));
        uint256 previewInWant;
        {
            uint256 underlyingToPreview = externalUnderlyingToken.balanceOf(address(this));
            uint256 shareBalance = externalShareToken.balanceOf(address(this));
            underlyingToPreview += previewRedeem(shareBalance);
            previewInWant = cooldownVault.previewDeposit(underlyingToPreview);
        }
        uint256 totalAsset = pendingInvested + previewInWant;
        if (remainingPredepositDebt > totalAsset) {
            return 0;
        } else {
            return totalAsset - remainingPredepositDebt;
        }
    }
    function _requireNoOutstandingDebt() internal view {
        if (cooldownVault.strategyShortfall(address(this)) > 0) revert OutstandingPredepositDebt();
        if (cooldownVault.strategyDebtOutstanding(address(this)) > 0) revert OutstandingPredepositDebt();
    }
}