pragma solidity ^0.8.24;
import { IEEPCondition } from "../interfaces/IEEPCondition.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
contract OracleCondition is IEEPCondition {
    uint256 public constant MAX_STALENESS = 1 hours;
    function conditionName() external pure override returns (string memory) {
        return "ChainlinkOracle";
    }
    function isSatisfied(
        uint256,
        address,
        bytes calldata data
    ) external view override returns (bool) {
        (address priceFeed, int256 targetPrice, bool releaseWhenAbove) =
            abi.decode(data, (address, int256, bool));
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
        require(block.timestamp - updatedAt <= MAX_STALENESS, "Oracle: stale price data");
        require(answer > 0, "Oracle: invalid price");
        return releaseWhenAbove ? answer >= targetPrice : answer <= targetPrice;
    }
    function encode(
        address priceFeed,
        int256 targetPrice,
        bool releaseWhenAbove
    ) external pure returns (bytes memory) {
        require(priceFeed != address(0), "Oracle: zero feed address");
        return abi.encode(priceFeed, targetPrice, releaseWhenAbove);
    }
    function currentPrice(address priceFeed) external view returns (int256 price, uint8 decimals) {
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeed);
        (, price, , , ) = feed.latestRoundData();
        decimals = feed.decimals();
    }
}