pragma solidity 0.8.6;
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "../Interfaces/Interfaces.sol";
import "./IHegicOperationalTreasury.sol";
import "./IHegicStrategy.sol";
abstract contract HegicStrategy is Ownable, IHegicStrategy {
    IHegicOperationalTreasury public immutable pool;
    AggregatorV3Interface public immutable priceProvider;
    uint8 public collateralizationRatio;
    uint256 public override lockedLimit;
    IPremiumCalculator public pricer;
    uint256 internal immutable spotDecimals;
    uint256 private constant K_DECIMALS = 100;
    uint256 public k = 100;
    struct StrategyData {
        uint128 amount;
        uint128 strike;
    }
    mapping(uint256 => StrategyData) public strategyData;
    constructor(
        IHegicOperationalTreasury _pool,
        AggregatorV3Interface _priceProvider,
        IPremiumCalculator _pricer,
        uint8 _collateralizationRatio,
        uint256 limit,
        uint8 _spotDecimals
    ) {
        pricer = _pricer;
        pool = _pool;
        priceProvider = _priceProvider;
        collateralizationRatio = _collateralizationRatio;
        lockedLimit = limit;
        spotDecimals = 10**_spotDecimals;
    }
    function setLimit(uint256 value) external onlyOwner {
        lockedLimit = value;
    }
    function getLockedByStrategy()
        external
        view
        override
        returns (uint256 amount)
    {
        return pool.lockedByStrategy(address(this));
    }
    function buy(
        address holder,
        uint32 period,
        uint128 amount,
        uint256 strike
    ) external virtual returns (uint256 id) {
        if (strike == 0) strike = _currentPrice();
        uint256 premium = _calculatePremium(period, amount, strike);
        uint128 lockedAmount = _calculateLockedAmount(amount, period, strike);
        require(
            pool.lockedByStrategy(address(this)) + lockedAmount <= lockedLimit,
            "HegicStrategy: The limit is exceeded"
        );
        pool.token().transferFrom(msg.sender, address(pool), premium);
        uint32 expiration = uint32(block.timestamp + period);
        id = pool.lockLiquidityFor(holder, lockedAmount, expiration);
        strategyData[id] = StrategyData(uint128(amount), uint128(strike));
    }
    function exercise(uint256 optionID) external {
        uint256 amount = _profitOf(optionID);
        require(
            pool.manager().isApprovedOrOwner(msg.sender, optionID),
            "HegicStrategy: Msg.sender can't exercise this option"
        );
        require(amount > 0, "HegicStrategy: The profit is zero");
        pool.payOff(optionID, amount, pool.manager().ownerOf(optionID));
    }
    function _calculateLockedAmount(
        uint128 amount,
        uint32 period,
        uint256 strike
    ) internal view virtual returns (uint128 lockedAmount) {
        return
            uint128(
                (pricer.calculatePremium(
                    uint32(period),
                    uint128(amount),
                    strike
                ) * k) / K_DECIMALS
            );
    }
    function _calculatePremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view virtual returns (uint256 premium) {
        if (strike == 0) strike = _currentPrice();
        premium = pricer.calculatePremium(period, amount, strike);
    }
    function _profitOf(uint256 optionID)
        internal
        view
        virtual
        returns (uint256 profit);
    function _currentPrice() internal view returns (uint256 price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        price = uint256(latestPrice);
    }
    function profitOf(uint256 optionID) external view returns (uint256 amount) {
        return _profitOf(optionID);
    }
    function setK(uint256 value) external onlyOwner {
        k = value;
    }
}