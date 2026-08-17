pragma solidity ^0.8.7;
contract FunctionUtils {
    uint256 public constant BASE_TOKENS = 10**18;
    uint256 public constant BASE_PARAMS = 10**9;
    function _piecewiseLinear(
        uint64 x,
        uint64[] memory xArray,
        uint64[] memory yArray
    ) internal pure returns (uint64) {
        if (x >= xArray[xArray.length - 1]) {
            return yArray[xArray.length - 1];
        } else if (x <= xArray[0]) {
            return yArray[0];
        } else {
            uint256 lower;
            uint256 upper = xArray.length - 1;
            uint256 mid;
            while (upper - lower > 1) {
                mid = lower + (upper - lower) / 2;
                if (xArray[mid] <= x) {
                    lower = mid;
                } else {
                    upper = mid;
                }
            }
            if (yArray[upper] > yArray[lower]) {
                return
                    yArray[lower] +
                    ((yArray[upper] - yArray[lower]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            } else {
                return
                    yArray[lower] -
                    ((yArray[lower] - yArray[upper]) * (x - xArray[lower])) /
                    (xArray[upper] - xArray[lower]);
            }
        }
    }
    modifier onlyCompatibleInputArrays(uint64[] memory xArray, uint64[] memory yArray) {
        require(xArray.length == yArray.length && xArray.length > 0, "5");
        for (uint256 i = 0; i <= yArray.length - 1; i++) {
            require(yArray[i] <= uint64(BASE_PARAMS) && xArray[i] <= uint64(BASE_PARAMS), "6");
            if (i > 0) {
                require(xArray[i] > xArray[i - 1], "7");
            }
        }
        _;
    }
    modifier onlyCompatibleFees(uint64 fees) {
        require(fees <= BASE_PARAMS, "4");
        _;
    }
    modifier zeroCheck(address newAddress) {
        require(newAddress != address(0), "0");
        _;
    }
}