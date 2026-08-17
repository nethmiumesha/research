pragma solidity ^0.8.6;
import "./InterestRateModel.sol";
contract WhitePaperInterestRateModel is InterestRateModel {
    event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock);
    uint256 private constant BASE = 1e18;
    uint public constant blocksPerYear = 2102400;
    uint public multiplierPerBlock;
    uint public baseRatePerBlock;
    constructor(uint baseRatePerYear, uint multiplierPerYear) public {
        baseRatePerBlock = baseRatePerYear / blocksPerYear;
        multiplierPerBlock = multiplierPerYear / blocksPerYear;
        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
    }
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        if (borrows == 0) {
            return 0;
        }
        return borrows * BASE / (cash + borrows - reserves);
    }
    function getBorrowRate(uint cash, uint borrows, uint reserves) override public view returns (uint) {
        uint ur = utilizationRate(cash, borrows, reserves);
        return (ur * multiplierPerBlock / BASE) + baseRatePerBlock;
    }
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) override public view returns (uint) {
        uint oneMinusReserveFactor = BASE - reserveFactorMantissa;
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate * oneMinusReserveFactor / BASE;
        return utilizationRate(cash, borrows, reserves) * rateToPool / BASE;
    }
}