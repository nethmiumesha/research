pragma solidity 0.8.6;
import "./HegicPool.sol";
contract HegicPUT is HegicPool {
    uint256 private immutable SpotDecimals;
    uint256 private immutable TokenDecimals;
    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        IOptionsManager manager,
        IPriceCalculator _pricer,
        IHegicStaking _settlementFeeRecipient,
        AggregatorV3Interface _priceProvider,
        uint8 spotDecimals,
        uint8 tokenDecimals
    )
        HegicPool(
            _token,
            name,
            symbol,
            manager,
            _pricer,
            _settlementFeeRecipient,
            _priceProvider
        )
    {
        SpotDecimals = 10**spotDecimals;
        TokenDecimals = 10**tokenDecimals;
    }
    function _profitOf(Option memory option)
        internal
        view
        override
        returns (uint256 amount)
    {
        uint256 currentPrice = _currentPrice();
        if (currentPrice > option.strike) return 0;
        uint256 priceDecimals = 10**priceProvider.decimals();
        return
            ((option.strike - currentPrice) * option.amount * TokenDecimals) /
            SpotDecimals /
            priceDecimals;
    }
    function _calculateLockedAmount(uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        uint256 priceDecimals = 10**priceProvider.decimals();
        return
            (amount *
                collateralizationRatio *
                _currentPrice() *
                TokenDecimals) /
            SpotDecimals /
            priceDecimals /
            100;
    }
}