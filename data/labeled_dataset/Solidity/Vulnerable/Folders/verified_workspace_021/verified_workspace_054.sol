pragma solidity ^0.5.16;
import "./FuturesMarketBase.sol";
contract MixinFuturesViews is FuturesMarketBase {
    function marketSizes() public view returns (uint long, uint short) {
        int size = int(marketSize);
        int skew = marketSkew;
        return (_abs(size.add(skew).div(2)), _abs(size.sub(skew).div(2)));
    }
    function marketDebt() external view returns (uint debt, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_marketDebt(price), isInvalid);
    }
    function currentFundingRate() external view returns (int) {
        (uint price, ) = assetPrice();
        return _currentFundingRate(price);
    }
    function unrecordedFunding() external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_unrecordedFunding(price), isInvalid);
    }
    function fundingSequenceLength() external view returns (uint) {
        return fundingSequence.length;
    }
    function notionalValue(address account) external view returns (int value, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_notionalValue(positions[account].size, price), isInvalid);
    }
    function profitLoss(address account) external view returns (int pnl, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_profitLoss(positions[account], price), isInvalid);
    }
    function accruedFunding(address account) external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_accruedFunding(positions[account], price), isInvalid);
    }
    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_remainingMargin(positions[account], price), isInvalid);
    }
    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        return (_accessibleMargin(positions[account], price), isInvalid);
    }
    function liquidationPrice(address account) external view returns (uint price, bool invalid) {
        (uint aPrice, bool isInvalid) = assetPrice();
        uint liqPrice = _approxLiquidationPrice(positions[account], aPrice);
        return (liqPrice, isInvalid);
    }
    function liquidationFee(address account) external view returns (uint) {
        (uint price, bool invalid) = assetPrice();
        if (!invalid && _canLiquidate(positions[account], price)) {
            return _liquidationFee(int(positions[account].size), price);
        } else {
            return 0;
        }
    }
    function canLiquidate(address account) external view returns (bool) {
        (uint price, bool invalid) = assetPrice();
        return !invalid && _canLiquidate(positions[account], price);
    }
    function orderFee(int sizeDelta) external view returns (uint fee, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        (uint dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFee(marketKey),
                makerFee: _makerFee(marketKey),
                trackingCode: bytes32(0)
            });
        return (_orderFee(params, dynamicFeeRate), isInvalid || tooVolatile);
    }
    function postTradeDetails(int sizeDelta, address sender)
        external
        view
        returns (
            uint margin,
            int size,
            uint price,
            uint liqPrice,
            uint fee,
            Status status
        )
    {
        bool invalid;
        (price, invalid) = assetPrice();
        if (invalid) {
            return (0, 0, 0, 0, 0, Status.InvalidPrice);
        }
        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFee(marketKey),
                makerFee: _makerFee(marketKey),
                trackingCode: bytes32(0)
            });
        (Position memory newPosition, uint fee_, Status status_) = _postTradeDetails(positions[sender], params);
        liqPrice = _approxLiquidationPrice(newPosition, newPosition.lastPrice);
        return (newPosition.margin, newPosition.size, newPosition.lastPrice, liqPrice, fee_, status_);
    }
    function _approxLiquidationPrice(Position memory position, uint currentPrice) internal view returns (uint) {
        int positionSize = int(position.size);
        if (positionSize == 0) {
            return 0;
        }
        int fundingPerUnit = _netFundingPerUnit(position.lastFundingIndex, currentPrice);
        uint liqMargin = _liquidationMargin(positionSize, currentPrice);
        int result =
            int(position.lastPrice).add(int(liqMargin).sub(int(position.margin)).divideDecimal(positionSize)).sub(
                fundingPerUnit
            );
        return uint(_max(0, result));
    }
}