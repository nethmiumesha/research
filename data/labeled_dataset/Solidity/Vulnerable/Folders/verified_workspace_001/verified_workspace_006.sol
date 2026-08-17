pragma solidity 0.8.6;
import "../../libraries/ReplicationMath.sol";
import "../../libraries/Units.sol";
contract TestReplicationMath {
    using Units for uint256;
    uint256 public scaleFactorRisky;
    uint256 public scaleFactorStable;
    function set(uint256 prec0, uint256 prec1) public {
        scaleFactorRisky = prec0;
        scaleFactorStable = prec1;
    }
    function getProportionalVolatility(uint256 sigma, uint256 tau) public pure returns (int128 vol) {
        vol = ReplicationMath.getProportionalVolatility(sigma, tau);
    }
    function getStableGivenRisky(
        int128 invariantLast,
        uint256 reserveRisky,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128 reserveStable) {
        reserveStable = ReplicationMath
        .getStableGivenRisky(invariantLast, scaleFactorRisky, scaleFactorStable, reserveRisky, strike, sigma, tau)
        .scaleToX64(scaleFactorStable);
    }
    function getRiskyGivenStable(
        int128 invariantLast,
        uint256 reserveStable,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128 reserveRisky) {
        reserveRisky = ReplicationMath
        .getRiskyGivenStable(invariantLast, scaleFactorRisky, scaleFactorStable, reserveStable, strike, sigma, tau)
        .scaleToX64(scaleFactorRisky);
    }
    function calcInvariant(
        uint256 reserveRisky,
        uint256 reserveStable,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128 invariant) {
        invariant = ReplicationMath.calcInvariant(
            scaleFactorRisky,
            scaleFactorStable,
            reserveRisky,
            reserveStable,
            strike,
            sigma,
            tau
        );
    }
    function YEAR() public pure returns (uint256) {
        return Units.YEAR;
    }
    function PRECISION() public pure returns (uint256) {
        return Units.PRECISION;
    }
    function PERCENTAGE() public pure returns (uint256) {
        return Units.PERCENTAGE;
    }
}