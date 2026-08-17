pragma solidity ^0.6.12;
library QConstant {
    uint public constant CLOSE_FACTOR_MIN = 5e16;
    uint public constant CLOSE_FACTOR_MAX = 9e17;
    uint public constant COLLATERAL_FACTOR_MAX = 9e17;
    struct MarketInfo {
        bool isListed;
        uint borrowCap;
        uint collateralFactor;
    }
    struct BorrowInfo {
        uint borrow;
        uint interestIndex;
    }
    struct AccountSnapshot {
        uint qTokenBalance;
        uint borrowBalance;
        uint exchangeRate;
    }
    struct AccrueSnapshot {
        uint totalBorrow;
        uint totalReserve;
        uint accInterestIndex;
    }
}