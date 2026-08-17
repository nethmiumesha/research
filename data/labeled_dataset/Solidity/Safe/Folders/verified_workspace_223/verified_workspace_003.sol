pragma solidity 0.8.7;
contract TestChainlinkOracle {
    int256 public price = 100000000;
    uint8 public decimals = 8;
    string public description = "A mock Chainlink V3 Aggregator";
    uint256 public version = 3;
    uint80 private ROUND_ID = 1;
    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        uint80 roundId = ROUND_ID;
        int256 answer = price;
        uint256 startedAt = 0;
        uint256 updatedAt = block.timestamp;
        uint80 answeredInRound = ROUND_ID;
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
    function setPrice(int256 _price) public {
        price = _price;
    }
    function setDecimals(uint8 _decimals) external {
        decimals = _decimals;
    }
}