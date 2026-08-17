pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
interface IQValidator {
    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external returns (bool);
    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external returns (bool);
    function liquidateAllowed(
        address qTokenBorrowed,
        address borrower,
        uint repayAmount,
        uint closeFactor
    ) external returns (bool);
    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint actualRepayAmount
    ) external returns (uint qTokenAmount);
    function getAccountLiquidity(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external view returns (uint liquidity, uint shortfall);
    function getAccountLiquidityValue(address account) external view returns (uint collateralUSD, uint borrowUSD);
}