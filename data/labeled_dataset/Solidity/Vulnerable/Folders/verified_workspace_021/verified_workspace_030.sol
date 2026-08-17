pragma solidity ^0.5.16;
import "../FuturesMarket.sol";
contract TestableFuturesMarket is FuturesMarket {
    constructor(
        address _resolver,
        bytes32 _baseAsset,
        bytes32 _marketKey
    ) public FuturesMarket(_resolver, _baseAsset, _marketKey) {}
    function entryDebtCorrection() external view returns (int) {
        return _entryDebtCorrection;
    }
    function proportionalSkew() external view returns (int) {
        (uint price, ) = assetPrice();
        return _proportionalSkew(price);
    }
    function maxFundingRate() external view returns (uint) {
        return _maxFundingRate(marketKey);
    }
    function maxOrderSizes()
        external
        view
        returns (
            uint long,
            uint short,
            bool invalid
        )
    {
        uint price;
        (price, invalid) = assetPrice();
        int sizeLimit = int(_maxMarketValueUSD(marketKey)).divideDecimal(int(price));
        (uint longSize, uint shortSize) = marketSizes();
        long = uint(sizeLimit.sub(_min(int(longSize), sizeLimit)));
        short = uint(sizeLimit.sub(_min(int(shortSize), sizeLimit)));
        return (long, short, invalid);
    }
    function liquidationMargin(address account) external view returns (uint lMargin) {
        require(positions[account].size != 0, "0 size position");
        (uint price, ) = assetPrice();
        return _liquidationMargin(int(positions[account].size), price);
    }
    function currentLeverage(address account) external view returns (int leverage, bool invalid) {
        (uint price, bool isInvalid) = assetPrice();
        Position storage position = positions[account];
        uint remainingMargin_ = _remainingMargin(position, price);
        return (_currentLeverage(position, price, remainingMargin_), isInvalid);
    }
}