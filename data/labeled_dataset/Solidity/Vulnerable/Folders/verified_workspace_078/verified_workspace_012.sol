pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "../library/QConstant.sol";
interface IQToken {
    function underlying() external view returns (address);
    function totalSupply() external view returns (uint);
    function accountSnapshot(address account) external view returns (QConstant.AccountSnapshot memory);
    function underlyingBalanceOf(address account) external view returns (uint);
    function borrowBalanceOf(address account) external view returns (uint);
    function borrowRatePerSec() external view returns (uint);
    function supplyRatePerSec() external view returns (uint);
    function totalBorrow() external view returns (uint);
    function exchangeRate() external view returns (uint);
    function getCash() external view returns (uint);
    function getAccInterestIndex() external view returns (uint);
    function accruedAccountSnapshot(address account) external returns (QConstant.AccountSnapshot memory);
    function accruedUnderlyingBalanceOf(address account) external returns (uint);
    function accruedBorrowBalanceOf(address account) external returns (uint);
    function accruedTotalBorrow() external returns (uint);
    function accruedExchangeRate() external returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(
        address src,
        address dst,
        uint amount
    ) external returns (bool);
    function supply(address account, uint underlyingAmount) external payable returns (uint);
    function redeemToken(address account, uint qTokenAmount) external returns (uint);
    function redeemUnderlying(address account, uint underlyingAmount) external returns (uint);
    function borrow(address account, uint amount) external returns (uint);
    function repayBorrow(address account, uint amount) external payable returns (uint);
    function repayBorrowBehalf(
        address payer,
        address borrower,
        uint amount
    ) external payable returns (uint);
    function liquidateBorrow(
        address qTokenCollateral,
        address liquidator,
        address borrower,
        uint amount
    ) external payable returns (uint qAmountToSeize);
    function seize(
        address liquidator,
        address borrower,
        uint qTokenAmount
    ) external;
}