pragma solidity ^0.5.16;
import "./FuturesMarketBase.sol";
contract MixinFuturesNextPriceOrders is FuturesMarketBase {
    mapping(address => NextPriceOrder) public nextPriceOrders;
    function submitNextPriceOrder(int sizeDelta) external {
        _submitNextPriceOrder(sizeDelta, bytes32(0));
    }
    function submitNextPriceOrderWithTracking(int sizeDelta, bytes32 trackingCode) external {
        _submitNextPriceOrder(sizeDelta, trackingCode);
    }
    function _submitNextPriceOrder(int sizeDelta, bytes32 trackingCode) internal {
        require(nextPriceOrders[msg.sender].sizeDelta == 0, "previous order exists");
        Position storage position = positions[msg.sender];
        uint price = _assetPriceRequireSystemChecks();
        uint fundingIndex = _recomputeFunding(price);
        TradeParams memory params =
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFeeNextPrice(marketKey),
                makerFee: _makerFeeNextPrice(marketKey),
                trackingCode: trackingCode
            });
        (, , Status status) = _postTradeDetails(position, params);
        _revertIfError(status);
        uint commitDeposit = _nextPriceCommitDeposit(params);
        uint keeperDeposit = _minKeeperFee();
        _updatePositionMargin(position, price, -int(commitDeposit + keeperDeposit));
        emit PositionModified(position.id, msg.sender, position.margin, position.size, 0, price, fundingIndex, 0);
        uint targetRoundId = _exchangeRates().getCurrentRoundId(baseAsset) + 1;
        NextPriceOrder memory order =
            NextPriceOrder({
                sizeDelta: int128(sizeDelta),
                targetRoundId: uint128(targetRoundId),
                commitDeposit: uint128(commitDeposit),
                keeperDeposit: uint128(keeperDeposit),
                trackingCode: trackingCode
            });
        emit NextPriceOrderSubmitted(
            msg.sender,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
        nextPriceOrders[msg.sender] = order;
    }
    function cancelNextPriceOrder(address account) external {
        NextPriceOrder memory order = nextPriceOrders[account];
        require(order.sizeDelta != 0, "no previous order");
        uint currentRoundId = _exchangeRates().getCurrentRoundId(baseAsset);
        if (account == msg.sender) {
            Position storage position = positions[account];
            uint price = _assetPriceRequireSystemChecks();
            uint fundingIndex = _recomputeFunding(price);
            _updatePositionMargin(position, price, int(order.keeperDeposit));
            emit PositionModified(position.id, account, position.margin, position.size, 0, price, fundingIndex, 0);
        } else {
            require(_confirmationWindowOver(currentRoundId, order.targetRoundId), "cannot be cancelled by keeper yet");
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
        }
        _manager().payFee(order.commitDeposit);
        delete nextPriceOrders[account];
        emit NextPriceOrderRemoved(
            account,
            currentRoundId,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
    }
    function executeNextPriceOrder(address account) external {
        NextPriceOrder memory order = nextPriceOrders[account];
        require(order.sizeDelta != 0, "no previous order");
        uint currentRoundId = _exchangeRates().getCurrentRoundId(baseAsset);
        require(order.targetRoundId <= currentRoundId, "target roundId not reached");
        require(!_confirmationWindowOver(currentRoundId, order.targetRoundId), "order too old, use cancel");
        uint toRefund = order.commitDeposit;
        if (msg.sender == account) {
            toRefund += order.keeperDeposit;
        } else {
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
        }
        Position storage position = positions[account];
        uint currentPrice = _assetPriceRequireSystemChecks();
        uint fundingIndex = _recomputeFunding(currentPrice);
        _updatePositionMargin(position, currentPrice, int(toRefund));
        emit PositionModified(position.id, account, position.margin, position.size, 0, currentPrice, fundingIndex, 0);
        (uint pastPrice, ) = _exchangeRates().rateAndTimestampAtRound(baseAsset, order.targetRoundId);
        _trade(
            account,
            TradeParams({
                sizeDelta: order.sizeDelta,
                price: pastPrice,
                takerFee: _takerFeeNextPrice(marketKey),
                makerFee: _makerFeeNextPrice(marketKey),
                trackingCode: order.trackingCode
            })
        );
        delete nextPriceOrders[account];
        emit NextPriceOrderRemoved(
            account,
            currentRoundId,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
    }
    function _confirmationWindowOver(uint currentRoundId, uint targetRoundId) internal view returns (bool) {
        return (currentRoundId > targetRoundId) && (currentRoundId - targetRoundId > _nextPriceConfirmWindow(marketKey));
    }
    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(_exchangeCircuitBreaker().exchangeRates());
    }
    function _nextPriceCommitDeposit(TradeParams memory params) internal view returns (uint) {
        params.takerFee = _takerFee(marketKey);
        params.makerFee = _makerFee(marketKey);
        return _orderFee(params, 0);
    }
    event NextPriceOrderSubmitted(
        address indexed account,
        int sizeDelta,
        uint targetRoundId,
        uint commitDeposit,
        uint keeperDeposit,
        bytes32 trackingCode
    );
    event NextPriceOrderRemoved(
        address indexed account,
        uint currentRoundId,
        int sizeDelta,
        uint targetRoundId,
        uint commitDeposit,
        uint keeperDeposit,
        bytes32 trackingCode
    );
}