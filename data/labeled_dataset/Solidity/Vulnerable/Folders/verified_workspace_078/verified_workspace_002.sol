pragma solidity 0.6.12;
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/IRateModel.sol";
contract RateModelSlope is IRateModel, OwnableUpgradeable {
    using SafeMath for uint;
    uint private baseRatePerYear;
    uint private slopePerYearFirst;
    uint private slopePerYearSecond;
    uint private optimal;
    function initialize(
        uint _baseRatePerYear,
        uint _slopePerYearFirst,
        uint _slopePerYearSecond,
        uint _optimal
    ) external initializer {
        __Ownable_init();
        baseRatePerYear = _baseRatePerYear;
        slopePerYearFirst = _slopePerYearFirst;
        slopePerYearSecond = _slopePerYearSecond;
        optimal = _optimal;
    }
    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return Math.min(borrows.mul(1e18).div(cash.add(borrows).sub(reserves)), 1e18);
    }
    function getBorrowRate(
        uint cash,
        uint borrows,
        uint reserves
    ) public view override returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        if (optimal > 0 && utilization < optimal) {
            return baseRatePerYear.add(utilization.mul(slopePerYearFirst).div(optimal)).div(365 days);
        } else {
            uint ratio = utilization.sub(optimal).mul(1e18).div(uint(1e18).sub(optimal));
            return baseRatePerYear.add(slopePerYearFirst).add(ratio.mul(slopePerYearSecond).div(1e18)).div(365 days);
        }
    }
    function getSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor
    ) public view override returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactor);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}