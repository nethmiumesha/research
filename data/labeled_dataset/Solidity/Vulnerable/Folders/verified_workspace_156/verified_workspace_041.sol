pragma solidity ^0.8.24;
import { FixedPoint } from "./FixedPoint.sol";
library StableMath {
    using FixedPoint for uint256;
    error MaxImbalanceRatioExceeded();
    error StableInvariantDidNotConverge();
    error StableComputeBalanceDidNotConverge();
    uint256 public constant MAX_STABLE_TOKENS = 5;
    uint256 internal constant MIN_AMP = 1;
    uint256 internal constant MAX_AMP = 50000;
    uint256 internal constant AMP_PRECISION = 1e3;
    uint256 internal constant MAX_IMBALANCE_RATIO = 10_000;
    uint256 internal constant MIN_INVARIANT_RATIO = 60e16;
    uint256 internal constant MAX_INVARIANT_RATIO = 500e16;
    function computeInvariant(
        uint256 amplificationParameter,
        uint256[] memory balances
    ) internal pure returns (uint256) {
        uint256 sum = 0;
        uint256 numTokens = balances.length;
        for (uint256 i = 0; i < numTokens; ++i) {
            sum = sum + balances[i];
        }
        if (sum == 0) {
            return 0;
        }
        uint256 prevInvariant;
        uint256 invariant = sum;
        uint256 ampTimesTotal = amplificationParameter * numTokens;
        for (uint256 i = 0; i < 255; ++i) {
            uint256 D_P = invariant;
            for (uint256 j = 0; j < numTokens; ++j) {
                D_P = (D_P * invariant) / (balances[j] * numTokens);
            }
            prevInvariant = invariant;
            invariant =
                ((((ampTimesTotal * sum) / AMP_PRECISION) + (D_P * numTokens)) * invariant) /
                ((((ampTimesTotal - AMP_PRECISION) * invariant) / AMP_PRECISION) + ((numTokens + 1) * D_P));
            unchecked {
                if (invariant > prevInvariant) {
                    if (invariant - prevInvariant <= 1) {
                        return invariant;
                    }
                } else if (prevInvariant - invariant <= 1) {
                    return invariant;
                }
            }
        }
        revert StableInvariantDidNotConverge();
    }
    function computeOutGivenExactIn(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn,
        uint256 invariant
    ) internal pure returns (uint256) {
        balances[tokenIndexIn] += tokenAmountIn;
        uint256 finalBalanceOut = computeBalance(amplificationParameter, balances, invariant, tokenIndexOut);
        unchecked {
            balances[tokenIndexIn] -= tokenAmountIn;
        }
        return balances[tokenIndexOut] - finalBalanceOut - 1;
    }
    function computeInGivenExactOut(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountOut,
        uint256 invariant
    ) internal pure returns (uint256) {
        balances[tokenIndexOut] -= tokenAmountOut;
        uint256 finalBalanceIn = computeBalance(amplificationParameter, balances, invariant, tokenIndexIn);
        unchecked {
            balances[tokenIndexOut] += tokenAmountOut;
        }
        return finalBalanceIn - balances[tokenIndexIn] + 1;
    }
    function computeBalance(
        uint256 amplificationParameter,
        uint256[] memory balances,
        uint256 invariant,
        uint256 tokenIndex
    ) internal pure returns (uint256) {
        uint256 numTokens = balances.length;
        uint256 ampTimesTotal = amplificationParameter * numTokens;
        uint256 sum = balances[0];
        uint256 P_D = balances[0] * numTokens;
        for (uint256 j = 1; j < numTokens; ++j) {
            P_D = (P_D * balances[j] * numTokens) / invariant;
            sum = sum + balances[j];
        }
        sum = sum - balances[tokenIndex];
        uint256 inv2 = invariant * invariant;
        uint256 c = (inv2 * AMP_PRECISION).divUpRaw(ampTimesTotal * P_D) * balances[tokenIndex];
        uint256 b = sum + ((invariant * AMP_PRECISION) / ampTimesTotal);
        uint256 prevTokenBalance = 0;
        uint256 tokenBalance = (inv2 + c).divUpRaw(invariant + b);
        for (uint256 i = 0; i < 255; ++i) {
            prevTokenBalance = tokenBalance;
            tokenBalance = ((tokenBalance * tokenBalance) + c).divUpRaw((tokenBalance * 2) + b - invariant);
            unchecked {
                if (tokenBalance > prevTokenBalance) {
                    if (tokenBalance - prevTokenBalance <= 1) {
                        return tokenBalance;
                    }
                } else if (prevTokenBalance - tokenBalance <= 1) {
                    return tokenBalance;
                }
            }
        }
        revert StableComputeBalanceDidNotConverge();
    }
    function getMinAndMaxBalances(
        uint256[] memory balancesScaled18
    ) internal pure returns (uint256 minBalance, uint256 maxBalance) {
        minBalance = balancesScaled18[0];
        maxBalance = minBalance;
        uint256 length = balancesScaled18.length;
        for (uint256 i = 1; i < length; i++) {
            uint256 balance = balancesScaled18[i];
            if (balance < minBalance) {
                minBalance = balance;
            }
            if (balance > maxBalance) {
                maxBalance = balance;
            }
        }
    }
    function ensureBalancesWithinMaxImbalanceRange(uint256 minBalance, uint256 maxBalance) internal pure {
        uint256 imbalance = maxBalance / minBalance;
        if (imbalance >= MAX_IMBALANCE_RATIO) {
            revert MaxImbalanceRatioExceeded();
        }
    }
}