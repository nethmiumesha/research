pragma solidity 0.8.6;
import "./HegicStrategy.sol";
import "../Interfaces/Interfaces.sol";
contract HegicStrategyPut is HegicStrategy {
    uint256 private constant TOKEN_DECIMALS = 1e6;
     constructor(
         IHegicOperationalTreasury _pool,
         AggregatorV3Interface _priceProvider,
         IPremiumCalculator _pricer,
         uint8 _spotDecimals,
         uint256 limit
     ) HegicStrategy(_pool, _priceProvider, _pricer, 10, limit, _spotDecimals) {
     }
    function _profitOf(uint256 optionID)
        internal
        view
        override
        returns (uint256 amount)
    {
        StrategyData memory data = strategyData[optionID];
        uint256 currentPrice = _currentPrice();
        if (currentPrice > data.strike) return 0;
        uint256 priceDecimals = 10**priceProvider.decimals();
        return
            ((data.strike - currentPrice) * data.amount * TOKEN_DECIMALS) /
            spotDecimals /
            priceDecimals;
    }
}