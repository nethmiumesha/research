pragma solidity 0.8.17;
interface IVestingCurve {
    function getVestedPayoutAtTime(
        uint256 totalPayout,
        uint256 vestingTerm,
        uint256 startTimestamp,
        uint256 checkTimestamp
    ) external view returns (uint256 vestedPayout);
}