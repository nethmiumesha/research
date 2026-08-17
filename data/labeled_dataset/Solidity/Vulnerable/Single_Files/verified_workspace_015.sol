pragma solidity ^0.8.24;
interface IChainlinkFeed {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
contract CurvePoolOracle {
    IChainlinkFeed public immutable feed;
    constructor(address _feed) {
        feed = IChainlinkFeed(_feed);
    }
    function price() external view returns (uint256) {
        (, int256 answer, , , ) = feed.latestRoundData();
        require(answer > 0, "Invalid price");
        return uint256(answer);
    }
}