pragma solidity 0.8.17;
import "../interfaces/IVestingCurve.sol";
contract LinearVestingCurve is IVestingCurve {
    function getVestedPayoutAtTime(
        uint256 totalPayout,
        uint256 vestingTerm,
        uint256 startTimestamp,
        uint256 checkTimestamp
    ) external pure returns (uint256 vestedPayout) {
        if (checkTimestamp <= startTimestamp) {
            vestedPayout = 0;
        } else if (checkTimestamp >= (startTimestamp + vestingTerm)) {
            vestedPayout = totalPayout;
        } else {
            vestedPayout = (totalPayout * (checkTimestamp - startTimestamp)) / vestingTerm;
        }
    }
}