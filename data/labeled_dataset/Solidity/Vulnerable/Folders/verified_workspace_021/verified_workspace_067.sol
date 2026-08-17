pragma solidity ^0.5.16;
import "./PerpsV2SettingsMixin.sol";
import "./interfaces/IPerpsV2Market.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SignedSafeDecimalMath.sol";
import "./SafeDecimalMath.sol";
import "./interfaces/IExchangeCircuitBreaker.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IERC20.sol";
interface IFuturesMarketManagerInternal {
    function issueSUSD(address account, uint amount) external;
    function burnSUSD(address account, uint amount) external returns (uint postReclamationAmount);
    function payFee(uint amount, bytes32 trackingCode) external;
}
contract PerpsV2MarketBase is PerpsV2SettingsMixin, IPerpsV2BaseTypes {
    using SafeMath for uint;
    using SignedSafeMath for int;
    using SignedSafeDecimalMath for int;
    using SafeDecimalMath for uint;
    int private constant _UNIT = int(10**uint(18));
    bytes32 internal constant sUSD = "sUSD";
    bytes32 public marketKey;
    bytes32 public baseAsset;
    uint128 public marketSize;
    int128 public marketSkew;
    uint32 public fundingLastRecomputed;
    int128[] public fundingSequence;
    mapping(address => Position) public positions;
    mapping(uint => address) public positionIdOwner;
    int128 internal _entryDebtCorrection;
    uint64 public lastPositionId = 0;
    mapping(uint8 => string) internal _errorMessages;
    bytes32 public constant CONTRACT_NAME = "PerpsV2Market";
    bytes32 internal constant CONTRACT_CIRCUIT_BREAKER = "ExchangeCircuitBreaker";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";
    bytes32 internal constant CONTRACT_PERPSV2SETTINGS = "PerpsV2Settings";
    bytes32 internal constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    struct TradeParams {
        int sizeDelta;
        uint price;
        uint baseFee;
        bytes32 trackingCode;
    }
    constructor(
        address _resolver,
        bytes32 _baseAsset,
        bytes32 _marketKey
    ) public PerpsV2SettingsMixin(_resolver) {
        baseAsset = _baseAsset;
        marketKey = _marketKey;
        fundingSequence.push(0);
        _errorMessages[uint8(Status.InvalidPrice)] = "Invalid price";
        _errorMessages[uint8(Status.PriceOutOfBounds)] = "Price out of acceptable range";
        _errorMessages[uint8(Status.CanLiquidate)] = "Position can be liquidated";
        _errorMessages[uint8(Status.CannotLiquidate)] = "Position cannot be liquidated";
        _errorMessages[uint8(Status.MaxMarketSizeExceeded)] = "Max market size exceeded";
        _errorMessages[uint8(Status.MaxLeverageExceeded)] = "Max leverage exceeded";
        _errorMessages[uint8(Status.InsufficientMargin)] = "Insufficient margin";
        _errorMessages[uint8(Status.NotPermitted)] = "Not permitted by this address";
        _errorMessages[uint8(Status.NilOrder)] = "Cannot submit empty order";
        _errorMessages[uint8(Status.NoPositionOpen)] = "No position open";
        _errorMessages[uint8(Status.PriceTooVolatile)] = "Price too volatile";
    }
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = PerpsV2SettingsMixin.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](5);
        newAddresses[0] = CONTRACT_EXCHANGER;
        newAddresses[1] = CONTRACT_CIRCUIT_BREAKER;
        newAddresses[2] = CONTRACT_FUTURESMARKETMANAGER;
        newAddresses[3] = CONTRACT_PERPSV2SETTINGS;
        newAddresses[4] = CONTRACT_SYSTEMSTATUS;
        addresses = combineArrays(existingAddresses, newAddresses);
    }
    function _exchangeCircuitBreaker() internal view returns (IExchangeCircuitBreaker) {
        return IExchangeCircuitBreaker(requireAndGetAddress(CONTRACT_CIRCUIT_BREAKER));
    }
    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }
    function _systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }
    function _manager() internal view returns (IFuturesMarketManagerInternal) {
        return IFuturesMarketManagerInternal(requireAndGetAddress(CONTRACT_FUTURESMARKETMANAGER));
    }
    function _settings() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_PERPSV2SETTINGS);
    }
    function _proportionalSkew(uint price) internal view returns (int) {
        require(price > 0, "price can't be zero");
        uint skewScaleBaseAsset = _skewScaleUSD(marketKey).divideDecimal(price);
        require(skewScaleBaseAsset != 0, "skewScale is zero");
        return int(marketSkew).divideDecimal(int(skewScaleBaseAsset));
    }
    function _currentFundingRate(uint price) internal view returns (int) {
        int maxFundingRate = int(_maxFundingRate(marketKey));
        return _min(_max(-_UNIT, -_proportionalSkew(price)), _UNIT).multiplyDecimal(maxFundingRate);
    }
    function _unrecordedFunding(uint price) internal view returns (int funding) {
        int elapsed = int(block.timestamp.sub(fundingLastRecomputed));
        int currentFundingRatePerSecond = _currentFundingRate(price) / 1 days;
        return currentFundingRatePerSecond.multiplyDecimal(int(price)).mul(elapsed);
    }
    function _nextFundingEntry(uint price) internal view returns (int funding) {
        return int(fundingSequence[_latestFundingIndex()]).add(_unrecordedFunding(price));
    }
    function _netFundingPerUnit(uint startIndex, uint price) internal view returns (int) {
        return _nextFundingEntry(price).sub(fundingSequence[startIndex]);
    }
    function _orderSizeTooLarge(
        uint maxSize,
        int oldSize,
        int newSize
    ) internal view returns (bool) {
        if (_sameSide(oldSize, newSize) && _abs(newSize) <= _abs(oldSize)) {
            return false;
        }
        int newSkew = int(marketSkew).sub(oldSize).add(newSize);
        int newMarketSize = int(marketSize).sub(_signedAbs(oldSize)).add(_signedAbs(newSize));
        int newSideSize;
        if (0 < newSize) {
            newSideSize = newMarketSize.add(newSkew);
        } else {
            newSideSize = newMarketSize.sub(newSkew);
        }
        if (maxSize < _abs(newSideSize.div(2))) {
            return true;
        }
        return false;
    }
    function _notionalValue(int positionSize, uint price) internal pure returns (int value) {
        return positionSize.multiplyDecimal(int(price));
    }
    function _profitLoss(Position memory position, uint price) internal pure returns (int pnl) {
        int priceShift = int(price).sub(int(position.lastPrice));
        return int(position.size).multiplyDecimal(priceShift);
    }
    function _accruedFunding(Position memory position, uint price) internal view returns (int funding) {
        uint lastModifiedIndex = position.lastFundingIndex;
        if (lastModifiedIndex == 0) {
            return 0;
        }
        int net = _netFundingPerUnit(lastModifiedIndex, price);
        return int(position.size).multiplyDecimal(net);
    }
    function _marginPlusProfitFunding(Position memory position, uint price) internal view returns (int) {
        int funding = _accruedFunding(position, price);
        return int(position.margin).add(_profitLoss(position, price)).add(funding);
    }
    function _recomputeMarginWithDelta(
        Position memory position,
        uint price,
        int marginDelta
    ) internal view returns (uint margin, Status statusCode) {
        int newMargin = _marginPlusProfitFunding(position, price).add(marginDelta);
        if (newMargin < 0) {
            return (0, Status.InsufficientMargin);
        }
        uint uMargin = uint(newMargin);
        int positionSize = int(position.size);
        uint lMargin = _liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            return (uMargin, Status.CanLiquidate);
        }
        return (uMargin, Status.Ok);
    }
    function _remainingMargin(Position memory position, uint price) internal view returns (uint) {
        int remaining = _marginPlusProfitFunding(position, price);
        return uint(_max(0, remaining));
    }
    function _accessibleMargin(Position memory position, uint price) internal view returns (uint) {
        uint milli = uint(_UNIT / 1000);
        int maxLeverage = int(_maxLeverage(marketKey).sub(milli));
        uint inaccessible = _abs(_notionalValue(position.size, price).divideDecimal(maxLeverage));
        if (0 < inaccessible) {
            uint minInitialMargin = _minInitialMargin();
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible.add(milli);
        }
        uint remaining = _remainingMargin(position, price);
        if (remaining <= inaccessible) {
            return 0;
        }
        return remaining.sub(inaccessible);
    }
    function _liquidationFee(int positionSize, uint price) internal view returns (uint lFee) {
        uint proportionalFee = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationFeeRatio());
        uint minFee = _minKeeperFee();
        return proportionalFee > minFee ? proportionalFee : minFee;
    }
    function _liquidationMargin(int positionSize, uint price) internal view returns (uint lMargin) {
        uint liquidationBuffer = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationBufferRatio());
        return liquidationBuffer.add(_liquidationFee(positionSize, price));
    }
    function _canLiquidate(Position memory position, uint price) internal view returns (bool) {
        if (position.size == 0) {
            return false;
        }
        return _remainingMargin(position, price) <= _liquidationMargin(int(position.size), price);
    }
    function _currentLeverage(
        Position memory position,
        uint price,
        uint remainingMargin_
    ) internal pure returns (int leverage) {
        if (remainingMargin_ == 0) {
            return 0;
        }
        return _notionalValue(position.size, price).divideDecimal(int(remainingMargin_));
    }
    function _orderFee(TradeParams memory params, uint dynamicFeeRate) internal pure returns (uint fee) {
        int notionalDiff = params.sizeDelta.multiplyDecimal(int(params.price));
        uint feeRate = params.baseFee.add(dynamicFeeRate);
        return _abs(notionalDiff.multiplyDecimal(int(feeRate)));
    }
    function _dynamicFeeRate() internal view returns (uint feeRate, bool tooVolatile) {
        return _exchanger().dynamicFeeRateForExchange(sUSD, baseAsset);
    }
    function _latestFundingIndex() internal view returns (uint) {
        return fundingSequence.length.sub(1);
    }
    function _postTradeDetails(Position memory oldPos, TradeParams memory params)
        internal
        view
        returns (
            Position memory newPosition,
            uint fee,
            Status tradeStatus
        )
    {
        if (params.sizeDelta == 0) {
            return (oldPos, 0, Status.NilOrder);
        }
        if (_canLiquidate(oldPos, params.price)) {
            return (oldPos, 0, Status.CanLiquidate);
        }
        (uint dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        if (tooVolatile) {
            return (oldPos, 0, Status.PriceTooVolatile);
        }
        fee = _orderFee(params, dynamicFeeRate);
        (uint newMargin, Status status) = _recomputeMarginWithDelta(oldPos, params.price, -int(fee));
        if (_isError(status)) {
            return (oldPos, 0, status);
        }
        Position memory newPos =
            Position({
                id: oldPos.id,
                lastFundingIndex: uint64(_latestFundingIndex()),
                margin: uint128(newMargin),
                lastPrice: uint128(params.price),
                size: int128(int(oldPos.size).add(params.sizeDelta))
            });
        bool positionDecreasing = _sameSide(oldPos.size, newPos.size) && _abs(newPos.size) < _abs(oldPos.size);
        if (!positionDecreasing) {
            if (uint(newPos.margin).add(fee) < _minInitialMargin()) {
                return (oldPos, 0, Status.InsufficientMargin);
            }
        }
        if (newMargin <= _liquidationMargin(newPos.size, params.price)) {
            return (newPos, 0, Status.CanLiquidate);
        }
        {
            int leverage = int(newPos.size).multiplyDecimal(int(params.price)).divideDecimal(int(newMargin.add(fee)));
            if (_maxLeverage(marketKey).add(uint(_UNIT) / 100) < _abs(leverage)) {
                return (oldPos, 0, Status.MaxLeverageExceeded);
            }
        }
        if (
            _orderSizeTooLarge(
                uint(int(_maxSingleSideValueUSD(marketKey).add(100 * uint(_UNIT))).divideDecimal(int(params.price))),
                oldPos.size,
                newPos.size
            )
        ) {
            return (oldPos, 0, Status.MaxMarketSizeExceeded);
        }
        return (newPos, fee, Status.Ok);
    }
    function _signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }
    function _abs(int x) internal pure returns (uint) {
        return uint(_signedAbs(x));
    }
    function _max(int x, int y) internal pure returns (int) {
        return x < y ? y : x;
    }
    function _min(int x, int y) internal pure returns (int) {
        return x < y ? x : y;
    }
    function _sameSide(int a, int b) internal pure returns (bool) {
        return (a >= 0) == (b >= 0);
    }
    function _isError(Status status) internal pure returns (bool) {
        return status != Status.Ok;
    }
    function _revertIfError(bool isError, Status status) internal view {
        if (isError) {
            revert(_errorMessages[uint8(status)]);
        }
    }
    function _revertIfError(Status status) internal view {
        if (_isError(status)) {
            revert(_errorMessages[uint8(status)]);
        }
    }
    function assetPrice() public view returns (uint price, bool invalid) {
        (price, invalid) = _exchangeCircuitBreaker().rateWithInvalid(baseAsset);
        return (price, invalid);
    }
    function _assetPriceRequireSystemChecks(bool allowMarketPaused) internal returns (uint) {
        if (allowMarketPaused) {
            _systemStatus().requireFuturesActive();
        } else {
            _systemStatus().requireFuturesMarketActive(marketKey);
        }
        (uint price, bool invalid) = _exchangeCircuitBreaker().rateWithInvalid(baseAsset);
        _revertIfError(invalid, Status.InvalidPrice);
        _exchangeCircuitBreaker().rateWithBreakCircuit(baseAsset);
        return price;
    }
    function _assetPriceRequireSystemChecks() internal returns (uint) {
        return _assetPriceRequireSystemChecks(false);
    }
    function _recomputeFunding(uint price) internal returns (uint lastIndex) {
        uint sequenceLengthBefore = fundingSequence.length;
        int funding = _nextFundingEntry(price);
        fundingSequence.push(int128(funding));
        fundingLastRecomputed = uint32(block.timestamp);
        emit FundingRecomputed(funding, sequenceLengthBefore, fundingLastRecomputed);
        return sequenceLengthBefore;
    }
    function recomputeFunding() external returns (uint lastIndex) {
        _revertIfError(msg.sender != _settings(), Status.NotPermitted);
        (uint price, bool invalid) = assetPrice();
        require(!invalid, "Invalid price");
        return _recomputeFunding(price);
    }
    function _positionDebtCorrection(Position memory position) internal view returns (int) {
        return
            int(position.margin).sub(
                int(position.size).multiplyDecimal(int(position.lastPrice).add(fundingSequence[position.lastFundingIndex]))
            );
    }
    function _marketDebt(uint price) internal view returns (uint) {
        if (marketSkew == 0 && _entryDebtCorrection == 0) {
            return 0;
        }
        int priceWithFunding = int(price).add(_nextFundingEntry(price));
        int totalDebt = int(marketSkew).multiplyDecimal(priceWithFunding).add(_entryDebtCorrection);
        return uint(_max(totalDebt, 0));
    }
    function _applyDebtCorrection(Position memory newPosition, Position memory oldPosition) internal {
        int newCorrection = _positionDebtCorrection(newPosition);
        int oldCorrection = _positionDebtCorrection(oldPosition);
        _entryDebtCorrection = int128(int(_entryDebtCorrection).add(newCorrection).sub(oldCorrection));
    }
    function _transferMargin(
        int marginDelta,
        uint price,
        address sender
    ) internal {
        uint absDelta = _abs(marginDelta);
        if (marginDelta > 0) {
            uint postReclamationAmount = _manager().burnSUSD(sender, absDelta);
            if (postReclamationAmount != absDelta) {
                marginDelta = int(postReclamationAmount);
            }
        } else if (marginDelta < 0) {
            _manager().issueSUSD(sender, absDelta);
        } else {
            return;
        }
        Position storage position = positions[sender];
        _initPosition(sender, position);
        _updatePositionMargin(position, price, marginDelta);
        emit MarginTransferred(sender, marginDelta);
        emit PositionModified(position.id, sender, position.margin, position.size, 0, price, _latestFundingIndex(), 0);
    }
    function _initPosition(address account, Position storage position) internal {
        if (position.id == 0) {
            lastPositionId++;
            uint64 id = lastPositionId;
            position.id = id;
            positionIdOwner[id] = account;
        }
    }
    function _updatePositionMargin(
        Position storage position,
        uint price,
        int marginDelta
    ) internal {
        Position memory oldPosition = position;
        (uint margin, Status status) = _recomputeMarginWithDelta(oldPosition, price, marginDelta);
        _revertIfError(status);
        int positionSize = position.size;
        uint fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), uint128(margin), uint128(price), int128(positionSize)),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(positionSize))
        );
        position.margin = uint128(margin);
        if (positionSize != 0) {
            position.lastPrice = uint128(price);
            position.lastFundingIndex = uint64(fundingIndex);
            if (marginDelta < 0) {
                _revertIfError(
                    (margin < _minInitialMargin()) ||
                        (margin <= _liquidationMargin(position.size, price)) ||
                        (_maxLeverage(marketKey) < _abs(_currentLeverage(position, price, margin))),
                    Status.InsufficientMargin
                );
            }
        }
    }
    function transferMargin(int marginDelta) external {
        bool allowMarketPaused = marginDelta > 0;
        uint price = _assetPriceRequireSystemChecks(allowMarketPaused);
        _recomputeFunding(price);
        _transferMargin(marginDelta, price, msg.sender);
    }
    function withdrawAllMargin() external {
        address sender = msg.sender;
        uint price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        int marginDelta = -int(_accessibleMargin(positions[sender], price));
        _transferMargin(marginDelta, price, sender);
    }
    function _trade(address sender, TradeParams memory params) internal {
        Position storage position = positions[sender];
        Position memory oldPosition = position;
        (Position memory newPosition, uint fee, Status status) = _postTradeDetails(oldPosition, params);
        _revertIfError(status);
        marketSkew = int128(int(marketSkew).add(newPosition.size).sub(oldPosition.size));
        marketSize = uint128(uint(marketSize).add(_abs(newPosition.size)).sub(_abs(oldPosition.size)));
        if (0 < fee) {
            _manager().payFee(fee, params.trackingCode);
            if (params.trackingCode != bytes32(0)) {
                emit Tracking(params.trackingCode, baseAsset, marketKey, params.sizeDelta, fee);
            }
        }
        position.margin = newPosition.margin;
        _applyDebtCorrection(newPosition, oldPosition);
        uint64 id = oldPosition.id;
        uint fundingIndex = _latestFundingIndex();
        position.size = newPosition.size;
        position.lastPrice = uint128(params.price);
        position.lastFundingIndex = uint64(fundingIndex);
        emit PositionModified(
            id,
            sender,
            newPosition.margin,
            newPosition.size,
            params.sizeDelta,
            params.price,
            fundingIndex,
            fee
        );
    }
    function modifyPosition(int sizeDelta) external {
        _modifyPosition(sizeDelta, bytes32(0));
    }
    function modifyPositionWithTracking(int sizeDelta, bytes32 trackingCode) external {
        _modifyPosition(sizeDelta, trackingCode);
    }
    function _modifyPosition(int sizeDelta, bytes32 trackingCode) internal {
        uint price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        _trade(
            msg.sender,
            TradeParams({sizeDelta: sizeDelta, price: price, baseFee: _baseFee(marketKey), trackingCode: trackingCode})
        );
    }
    function closePosition() external {
        _closePosition(bytes32(0));
    }
    function closePositionWithTracking(bytes32 trackingCode) external {
        _closePosition(trackingCode);
    }
    function _closePosition(bytes32 trackingCode) internal {
        int size = positions[msg.sender].size;
        _revertIfError(size == 0, Status.NoPositionOpen);
        uint price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        _trade(
            msg.sender,
            TradeParams({sizeDelta: -size, price: price, baseFee: _baseFee(marketKey), trackingCode: trackingCode})
        );
    }
    function _liquidatePosition(
        address account,
        address liquidator,
        uint price
    ) internal {
        Position storage position = positions[account];
        uint remMargin = _remainingMargin(position, price);
        int positionSize = position.size;
        uint positionId = position.id;
        marketSkew = int128(int(marketSkew).sub(positionSize));
        marketSize = uint128(uint(marketSize).sub(_abs(positionSize)));
        uint fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), 0, uint128(price), 0),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(positionSize))
        );
        delete positions[account].size;
        delete positions[account].margin;
        uint liqFee = _liquidationFee(positionSize, price);
        _manager().issueSUSD(liquidator, liqFee);
        emit PositionModified(positionId, account, 0, 0, 0, price, fundingIndex, 0);
        emit PositionLiquidated(positionId, account, liquidator, positionSize, price, liqFee);
        if (remMargin > liqFee) {
            _manager().payFee(remMargin.sub(liqFee), bytes32(0));
        }
    }
    function liquidatePosition(address account) external {
        uint price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        _revertIfError(!_canLiquidate(positions[account], price), Status.CannotLiquidate);
        _liquidatePosition(account, msg.sender, price);
    }
    event MarginTransferred(address indexed account, int marginDelta);
    event PositionModified(
        uint indexed id,
        address indexed account,
        uint margin,
        int size,
        int tradeSize,
        uint lastPrice,
        uint fundingIndex,
        uint fee
    );
    event PositionLiquidated(
        uint indexed id,
        address indexed account,
        address indexed liquidator,
        int size,
        uint price,
        uint fee
    );
    event FundingRecomputed(int funding, uint index, uint timestamp);
    event Tracking(bytes32 indexed trackingCode, bytes32 baseAsset, bytes32 marketKey, int sizeDelta, uint fee);
}