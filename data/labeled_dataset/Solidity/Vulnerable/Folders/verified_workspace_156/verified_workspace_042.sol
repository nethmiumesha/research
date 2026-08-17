pragma solidity ^0.8.24;
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ISwapFeePercentageBounds } from "@balancer-labs/v3-interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {
    IUnbalancedLiquidityInvariantRatioBounds
} from "@balancer-labs/v3-interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";
import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    IStablePool,
    StablePoolDynamicData,
    StablePoolImmutableData,
    AmplificationState
} from "@balancer-labs/v3-interfaces/contracts/pool-stable/IStablePool.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { BasePoolAuthentication } from "@balancer-labs/v3-pool-utils/contracts/BasePoolAuthentication.sol";
import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { StableMath } from "@balancer-labs/v3-solidity-utils/contracts/math/StableMath.sol";
import { Version } from "@balancer-labs/v3-solidity-utils/contracts/helpers/Version.sol";
import { PoolInfo } from "@balancer-labs/v3-pool-utils/contracts/PoolInfo.sol";
contract StablePool is IStablePool, BalancerPoolToken, BasePoolAuthentication, PoolInfo, Version {
    using FixedPoint for uint256;
    using SafeCast for *;
    struct NewPoolParams {
        string name;
        string symbol;
        uint256 amplificationParameter;
        string version;
    }
    uint256 private constant _MIN_UPDATE_TIME = 1 days;
    uint256 private constant _MAX_AMP_UPDATE_DAILY_RATE = 2;
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12;
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 10e16;
    AmplificationState private _amplificationState;
    event AmpUpdateStarted(uint256 startValue, uint256 endValue, uint256 startTime, uint256 endTime);
    event AmpUpdateStopped(uint256 currentValue);
    error AmplificationFactorTooLow();
    error AmplificationFactorTooHigh();
    error AmpUpdateDurationTooShort();
    error AmpUpdateRateTooFast();
    error AmpUpdateAlreadyStarted();
    error AmpUpdateNotStarted();
    constructor(
        NewPoolParams memory params,
        IVault vault
    )
        BalancerPoolToken(vault, params.name, params.symbol)
        BasePoolAuthentication(vault, msg.sender)
        PoolInfo(vault)
        Version(params.version)
    {
        if (params.amplificationParameter < StableMath.MIN_AMP) {
            revert AmplificationFactorTooLow();
        }
        if (params.amplificationParameter > StableMath.MAX_AMP) {
            revert AmplificationFactorTooHigh();
        }
        uint256 initialAmp = params.amplificationParameter * StableMath.AMP_PRECISION;
        _stopAmplification(initialAmp);
    }
    function computeInvariant(
        uint256[] memory balancesLiveScaled18,
        Rounding rounding
    ) external view returns (uint256 invariant) {
        (uint256 currentAmp, ) = _getAmplificationParameter();
        (uint256 minBalance, uint256 maxBalance) = StableMath.getMinAndMaxBalances(balancesLiveScaled18);
        StableMath.ensureBalancesWithinMaxImbalanceRange(minBalance, maxBalance);
        invariant = _computeInvariant(balancesLiveScaled18, currentAmp, rounding);
    }
    function _computeInvariant(
        uint256[] memory balancesLiveScaled18,
        uint256 currentAmp,
        Rounding rounding
    ) internal pure returns (uint256 invariant) {
        invariant = StableMath.computeInvariant(currentAmp, balancesLiveScaled18);
        if (invariant > 0) {
            invariant = rounding == Rounding.ROUND_DOWN ? invariant : invariant + 1;
        }
    }
    function computeBalance(
        uint256[] memory balancesLiveScaled18,
        uint256 tokenInIndex,
        uint256 invariantRatio
    ) external view returns (uint256 newBalance) {
        (uint256 minBalance, uint256 maxBalance) = StableMath.getMinAndMaxBalances(balancesLiveScaled18);
        (uint256 currentAmp, ) = _getAmplificationParameter();
        newBalance = StableMath.computeBalance(
            currentAmp,
            balancesLiveScaled18,
            _computeInvariant(balancesLiveScaled18, currentAmp, Rounding.ROUND_UP).mulUp(invariantRatio),
            tokenInIndex
        );
        if (newBalance < minBalance) {
            minBalance = newBalance;
        } else if (newBalance > maxBalance) {
            maxBalance = newBalance;
        }
        StableMath.ensureBalancesWithinMaxImbalanceRange(minBalance, maxBalance);
    }
    function onSwap(PoolSwapParams memory request) external view virtual returns (uint256 amountCalculatedScaled18) {
        (uint256 minBalance, uint256 maxBalance) = StableMath.getMinAndMaxBalances(request.balancesScaled18);
        (uint256 currentAmp, ) = _getAmplificationParameter();
        uint256 invariant = _computeInvariant(request.balancesScaled18, currentAmp, Rounding.ROUND_DOWN);
        uint256 amountOutScaled18;
        uint256 amountInScaled18;
        if (request.kind == SwapKind.EXACT_IN) {
            amountInScaled18 = request.amountGivenScaled18;
            amountOutScaled18 = StableMath.computeOutGivenExactIn(
                currentAmp,
                request.balancesScaled18,
                request.indexIn,
                request.indexOut,
                request.amountGivenScaled18,
                invariant
            );
            amountCalculatedScaled18 = amountOutScaled18;
        } else {
            amountInScaled18 = StableMath.computeInGivenExactOut(
                currentAmp,
                request.balancesScaled18,
                request.indexIn,
                request.indexOut,
                request.amountGivenScaled18,
                invariant
            );
            amountOutScaled18 = request.amountGivenScaled18;
            amountCalculatedScaled18 = amountInScaled18;
        }
        uint256 newBalanceIn = request.balancesScaled18[request.indexIn] + amountInScaled18;
        uint256 newBalanceOut = request.balancesScaled18[request.indexOut] - amountOutScaled18;
        if (newBalanceIn > maxBalance) {
            maxBalance = newBalanceIn;
        }
        if (newBalanceOut < minBalance) {
            minBalance = newBalanceOut;
        }
        StableMath.ensureBalancesWithinMaxImbalanceRange(minBalance, maxBalance);
    }
    function startAmplificationParameterUpdate(
        uint256 rawEndValue,
        uint256 endTime
    ) external onlySwapFeeManagerOrGovernance(address(this)) {
        if (rawEndValue < StableMath.MIN_AMP) {
            revert AmplificationFactorTooLow();
        }
        if (rawEndValue > StableMath.MAX_AMP) {
            revert AmplificationFactorTooHigh();
        }
        uint256 duration = endTime - block.timestamp;
        if (duration < _MIN_UPDATE_TIME) {
            revert AmpUpdateDurationTooShort();
        }
        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter();
        if (isUpdating) {
            revert AmpUpdateAlreadyStarted();
        }
        uint256 endValue = rawEndValue * StableMath.AMP_PRECISION;
        uint256 dailyRate = endValue > currentValue
            ? (endValue * 1 days).divUpRaw(currentValue * duration)
            : (currentValue * 1 days).divUpRaw(endValue * duration);
        if (dailyRate > _MAX_AMP_UPDATE_DAILY_RATE) {
            revert AmpUpdateRateTooFast();
        }
        uint64 currentValueUint64 = currentValue.toUint64();
        uint64 endValueUint64 = endValue.toUint64();
        uint32 startTimeUint32 = block.timestamp.toUint32();
        uint32 endTimeUint32 = endTime.toUint32();
        _amplificationState.startValue = currentValueUint64;
        _amplificationState.endValue = endValueUint64;
        _amplificationState.startTime = startTimeUint32;
        _amplificationState.endTime = endTimeUint32;
        emit AmpUpdateStarted(currentValueUint64, endValueUint64, startTimeUint32, endTimeUint32);
        _vault.emitAuxiliaryEvent(
            "AmpUpdateStarted",
            abi.encode(currentValueUint64, endValueUint64, startTimeUint32, endTimeUint32)
        );
    }
    function stopAmplificationParameterUpdate() external onlySwapFeeManagerOrGovernance(address(this)) {
        (uint256 currentValue, bool isUpdating) = _getAmplificationParameter();
        if (isUpdating == false) {
            revert AmpUpdateNotStarted();
        }
        _stopAmplification(currentValue);
        _vault.emitAuxiliaryEvent("AmpUpdateStopped", abi.encode(currentValue));
    }
    function getAmplificationParameter() external view returns (uint256 value, bool isUpdating, uint256 precision) {
        (value, isUpdating) = _getAmplificationParameter();
        precision = StableMath.AMP_PRECISION;
    }
    function getAmplificationState()
        external
        view
        returns (AmplificationState memory amplificationState, uint256 precision)
    {
        amplificationState = _amplificationState;
        precision = StableMath.AMP_PRECISION;
    }
    function _getAmplificationParameter() internal view returns (uint256 value, bool isUpdating) {
        AmplificationState memory state = _amplificationState;
        (uint256 startValue, uint256 endValue, uint256 startTime, uint256 endTime) = (
            state.startValue,
            state.endValue,
            state.startTime,
            state.endTime
        );
        if (block.timestamp < endTime) {
            isUpdating = true;
            unchecked {
                if (endValue > startValue) {
                    value =
                        startValue +
                        ((endValue - startValue) * (block.timestamp - startTime)) /
                        (endTime - startTime);
                } else {
                    value =
                        startValue -
                        ((startValue - endValue) * (block.timestamp - startTime)) /
                        (endTime - startTime);
                }
            }
        } else {
            isUpdating = false;
            value = endValue;
        }
    }
    function _stopAmplification(uint256 value) internal {
        uint64 currentValueUint64 = value.toUint64();
        _amplificationState.startValue = currentValueUint64;
        _amplificationState.endValue = currentValueUint64;
        uint32 currentTime = block.timestamp.toUint32();
        _amplificationState.startTime = currentTime;
        _amplificationState.endTime = currentTime;
        emit AmpUpdateStopped(currentValueUint64);
    }
    function getMinimumSwapFeePercentage() external pure returns (uint256) {
        return _MIN_SWAP_FEE_PERCENTAGE;
    }
    function getMaximumSwapFeePercentage() external pure returns (uint256) {
        return _MAX_SWAP_FEE_PERCENTAGE;
    }
    function getMinimumInvariantRatio() external pure returns (uint256) {
        return StableMath.MIN_INVARIANT_RATIO;
    }
    function getMaximumInvariantRatio() external pure returns (uint256) {
        return StableMath.MAX_INVARIANT_RATIO;
    }
    function getStablePoolDynamicData() external view returns (StablePoolDynamicData memory data) {
        data.balancesLiveScaled18 = _vault.getCurrentLiveBalances(address(this));
        (, data.tokenRates) = _vault.getPoolTokenRates(address(this));
        data.staticSwapFeePercentage = _vault.getStaticSwapFeePercentage((address(this)));
        data.totalSupply = totalSupply();
        data.bptRate = getRate();
        (data.amplificationParameter, data.isAmpUpdating) = _getAmplificationParameter();
        AmplificationState memory state = _amplificationState;
        data.startValue = state.startValue;
        data.endValue = state.endValue;
        data.startTime = state.startTime;
        data.endTime = state.endTime;
        PoolConfig memory poolConfig = _vault.getPoolConfig(address(this));
        data.isPoolInitialized = poolConfig.isPoolInitialized;
        data.isPoolPaused = poolConfig.isPoolPaused;
        data.isPoolInRecoveryMode = poolConfig.isPoolInRecoveryMode;
    }
    function getStablePoolImmutableData() external view returns (StablePoolImmutableData memory data) {
        data.tokens = _vault.getPoolTokens(address(this));
        (data.decimalScalingFactors, ) = _vault.getPoolTokenRates(address(this));
        data.amplificationParameterPrecision = StableMath.AMP_PRECISION;
    }
}