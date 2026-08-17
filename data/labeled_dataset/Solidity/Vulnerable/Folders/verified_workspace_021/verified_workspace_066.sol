pragma solidity ^0.5.16;
import "./PerpsV2MarketBase.sol";
import "./PerpsV2NextPriceMixin.sol";
import "./PerpsV2ViewsMixin.sol";
import "./interfaces/IPerpsV2Market.sol";
contract PerpsV2Market is IPerpsV2Market, PerpsV2MarketBase, PerpsV2NextPriceMixin, PerpsV2ViewsMixin {
    constructor(
        address _resolver,
        bytes32 _baseAsset,
        bytes32 _marketKey
    ) public PerpsV2MarketBase(_resolver, _baseAsset, _marketKey) {}
}