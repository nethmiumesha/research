pragma solidity ^0.7.0;
import "../pools/weighted/WeightedMath.sol";
contract MockWeightedMath is WeightedMath {
    function invariant(uint256[] calldata normalizedWeights, uint256[] calldata balances)
        external
        pure
        returns (uint256)
    {
        return _calculateInvariant(normalizedWeights, balances);
    }
    function outGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn
    ) external pure returns (uint256) {
        return _calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn);
    }
    function inGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut
    ) external pure returns (uint256) {
        return _calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut);
    }
    function exactTokensInForBPTOut(
        uint256[] calldata balances,
        uint256[] calldata normalizedWeights,
        uint256[] calldata amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcBptOutGivenExactTokensIn(balances, normalizedWeights, amountsIn, bptTotalSupply, swapFee);
    }
    function tokenInForExactBPTOut(
        uint256 tokenBalance,
        uint256 tokenNormalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcTokenInGivenExactBptOut(tokenBalance, tokenNormalizedWeight, bptAmountOut, bptTotalSupply, swapFee);
    }
    function exactBPTInForTokenOut(
        uint256 tokenBalance,
        uint256 tokenNormalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcTokenOutGivenExactBptIn(tokenBalance, tokenNormalizedWeight, bptAmountIn, bptTotalSupply, swapFee);
    }
    function exactBPTInForTokensOut(
        uint256[] calldata currentBalances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) external pure returns (uint256[] memory) {
        return _calcTokensOutGivenExactBptIn(currentBalances, bptAmountIn, totalBPT);
    }
    function bptInForExactTokensOut(
        uint256[] calldata balances,
        uint256[] calldata normalizedWeights,
        uint256[] calldata amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFee
    ) external pure returns (uint256) {
        return _calcBptInGivenExactTokensOut(balances, normalizedWeights, amountsOut, bptTotalSupply, swapFee);
    }
    function calculateDueTokenProtocolSwapFee(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 previousInvariant,
        uint256 currentInvariant,
        uint256 protocolSwapFeePercentage
    ) external pure returns (uint256) {
        return
            _calcDueTokenProtocolSwapFee(
                balance,
                normalizedWeight,
                previousInvariant,
                currentInvariant,
                protocolSwapFeePercentage
            );
    }
}