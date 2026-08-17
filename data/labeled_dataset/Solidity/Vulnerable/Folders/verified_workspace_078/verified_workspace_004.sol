pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IQValidator.sol";
import "../interfaces/IQToken.sol";
import "../interfaces/IQore.sol";
import "../library/QConstant.sol";
contract QValidator is IQValidator, OwnableUpgradeable {
    using SafeMath for uint;
    IPriceCalculator public constant oracle = IPriceCalculator(0x20E5E35ba29dC3B540a1aee781D0814D5c77Bce6);
    IQore public qore;
    function initialize() external initializer {
        __Ownable_init();
    }
    function getAccountLiquidity(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) external view override returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;
        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);
            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }
        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }
    function getAccountLiquidityValue(address account)
        external
        view
        override
        returns (uint collateralUSD, uint borrowUSD)
    {
        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        collateralUSD = 0;
        borrowUSD = 0;
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accountSnapshot(account);
            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            collateralUSD = collateralUSD.add(snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18));
            borrowUSD = borrowUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
        }
    }
    function setQore(address _qore) external onlyOwner {
        require(_qore != address(0), "QValidator: invalid qore address");
        require(address(qore) == address(0), "QValidator: qore already set");
        qore = IQore(_qore);
    }
    function redeemAllowed(
        address qToken,
        address redeemer,
        uint redeemAmount
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(redeemer, qToken, redeemAmount, 0);
        return shortfall == 0;
    }
    function borrowAllowed(
        address qToken,
        address borrower,
        uint borrowAmount
    ) external override returns (bool) {
        require(qore.checkMembership(borrower, address(qToken)), "QValidator: enterMarket required");
        require(oracle.getUnderlyingPrice(address(qToken)) > 0, "QValidator: Underlying price error");
        uint borrowCap = qore.marketInfoOf(qToken).borrowCap;
        if (borrowCap != 0) {
            uint totalBorrows = IQToken(payable(qToken)).accruedTotalBorrow();
            uint nextTotalBorrows = totalBorrows.add(borrowAmount);
            require(nextTotalBorrows < borrowCap, "QValidator: market borrow cap reached");
        }
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, qToken, 0, borrowAmount);
        return shortfall == 0;
    }
    function liquidateAllowed(
        address qToken,
        address borrower,
        uint liquidateAmount,
        uint closeFactor
    ) external override returns (bool) {
        (, uint shortfall) = _getAccountLiquidityInternal(borrower, address(0), 0, 0);
        require(shortfall != 0, "QValidator: Insufficient shortfall");
        uint borrowBalance = IQToken(payable(qToken)).accruedBorrowBalanceOf(borrower);
        uint maxClose = closeFactor.mul(borrowBalance).div(1e18);
        return liquidateAmount <= maxClose;
    }
    function qTokenAmountToSeize(
        address qTokenBorrowed,
        address qTokenCollateral,
        uint amount
    ) external override returns (uint seizeQAmount) {
        uint priceBorrowed = oracle.getUnderlyingPrice(qTokenBorrowed);
        uint priceCollateral = oracle.getUnderlyingPrice(qTokenCollateral);
        require(priceBorrowed != 0 && priceCollateral != 0, "QValidator: price error");
        uint exchangeRate = IQToken(payable(qTokenCollateral)).accruedExchangeRate();
        require(exchangeRate != 0, "QValidator: exchangeRate of qTokenCollateral is zero");
        return amount.mul(qore.liquidationIncentive()).mul(priceBorrowed).div(priceCollateral.mul(exchangeRate));
    }
    function _getAccountLiquidityInternal(
        address account,
        address qToken,
        uint redeemAmount,
        uint borrowAmount
    ) private returns (uint liquidity, uint shortfall) {
        uint accCollateralValueInUSD;
        uint accBorrowValueInUSD;
        address[] memory assets = qore.marketListOf(account);
        uint[] memory prices = oracle.getUnderlyingPrices(assets);
        for (uint i = 0; i < assets.length; i++) {
            require(prices[i] != 0, "QValidator: price error");
            QConstant.AccountSnapshot memory snapshot = IQToken(payable(assets[i])).accruedAccountSnapshot(account);
            uint collateralValuePerShareInUSD = snapshot
                .exchangeRate
                .mul(prices[i])
                .mul(qore.marketInfoOf(payable(assets[i])).collateralFactor)
                .div(1e36);
            accCollateralValueInUSD = accCollateralValueInUSD.add(
                snapshot.qTokenBalance.mul(collateralValuePerShareInUSD).div(1e18)
            );
            accBorrowValueInUSD = accBorrowValueInUSD.add(snapshot.borrowBalance.mul(prices[i]).div(1e18));
            if (assets[i] == qToken) {
                accBorrowValueInUSD = accBorrowValueInUSD.add(redeemAmount.mul(collateralValuePerShareInUSD).div(1e18));
                accBorrowValueInUSD = accBorrowValueInUSD.add(borrowAmount.mul(prices[i]).div(1e18));
            }
        }
        liquidity = accCollateralValueInUSD > accBorrowValueInUSD
            ? accCollateralValueInUSD.sub(accBorrowValueInUSD)
            : 0;
        shortfall = accCollateralValueInUSD > accBorrowValueInUSD
            ? 0
            : accBorrowValueInUSD.sub(accCollateralValueInUSD);
    }
}