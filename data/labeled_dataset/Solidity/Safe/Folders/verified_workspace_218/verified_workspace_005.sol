pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./script.sol";
contract REPL is script {
    uint private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint private constant SQRT_1 = 13043817825332782212;
    uint private constant LOG_E_2 = 6931471806;
    uint private constant LOG_10_2 = 3010299957;
    uint private constant BASE = 1e10;
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;
        if (_n < 256) {
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        } else {
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (uint(1) << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }
        return res;
    }
    function generalLog(uint256 x) internal pure returns (uint) {
        uint res = 0;
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count;
            res = count * FIXED_1;
        }
        if (x > FIXED_1) {
            for (uint8 i = 127; i > 0; --i) {
                x = (x * x) / FIXED_1;
                if (x >= FIXED_2) {
                    x >>= 1;
                    res += uint(1) << (i - 1);
                }
            }
        }
        return res;
    }
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function stddev(uint[] memory numbers) public pure returns (uint sd, uint mean) {
        uint sum = 0;
        for(uint i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        mean = sum / numbers.length;
        sum = 0;
        uint i;
        for(i = 0; i < numbers.length; i++) {
            sum += (numbers[i] - mean) ** 2;
        }
        sd = sqrt(sum / (numbers.length - 1));
        return (sd, mean);
    }
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;
        uint256 y;
        uint256 z;
        z = y = x % 0x10000000000000000000000000000000;
        z = (z * y) / FIXED_1;
        res += z * 0x10e1b3be415a0000;
        z = (z * y) / FIXED_1;
        res += z * 0x05a0913f6b1e0000;
        z = (z * y) / FIXED_1;
        res += z * 0x0168244fdac78000;
        z = (z * y) / FIXED_1;
        res += z * 0x004807432bc18000;
        z = (z * y) / FIXED_1;
        res += z * 0x000c0135dca04000;
        z = (z * y) / FIXED_1;
        res += z * 0x0001b707b1cdc000;
        z = (z * y) / FIXED_1;
        res += z * 0x000036e0f639b800;
        z = (z * y) / FIXED_1;
        res += z * 0x00000618fee9f800;
        z = (z * y) / FIXED_1;
        res += z * 0x0000009c197dcc00;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000e30dce400;
        z = (z * y) / FIXED_1;
        res += z * 0x000000012ebd1300;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000017499f00;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000001a9d480;
        z = (z * y) / FIXED_1;
        res += z * 0x00000000001c6380;
        z = (z * y) / FIXED_1;
        res += z * 0x000000000001c638;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000001ab8;
        z = (z * y) / FIXED_1;
        res += z * 0x000000000000017c;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000014;
        z = (z * y) / FIXED_1;
        res += z * 0x0000000000000001;
        res = res / 0x21c3677c82b40000 + y + FIXED_1;
        if ((x & 0x010000000000000000000000000000000) != 0)
            res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776;
        if ((x & 0x020000000000000000000000000000000) != 0)
            res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4;
        if ((x & 0x040000000000000000000000000000000) != 0)
            res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
        if ((x & 0x080000000000000000000000000000000) != 0)
            res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
        if ((x & 0x100000000000000000000000000000000) != 0)
            res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea;
        if ((x & 0x200000000000000000000000000000000) != 0)
            res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d;
        if ((x & 0x400000000000000000000000000000000) != 0)
            res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11;
        return res;
    }
    function ncdf(uint x) internal pure returns (uint) {
        int t1 = int(1e7 + (2315419 * x / FIXED_1));
        uint exp = x / 2 * x / FIXED_1;
        int d = int(3989423 * FIXED_1 / optimalExp(uint(exp)));
        uint prob = uint(d * (3193815 + ( -3565638 + (17814780 + (-18212560 + 13302740 * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1) * 1e7 / t1);
        if( x > 0 ) prob = 1e14 - prob;
        return prob;
    }
    function vol(uint[] memory p) internal pure returns (uint x) {
        for (uint8 i = 1; i <= (p.length-1); i++) {
            x += ((generalLog(p[i] * FIXED_1) - generalLog(p[i-1] * FIXED_1)))**2;
        }
        x = sqrt(uint(252) * sqrt(x / (p.length-1)));
        return uint(1e18) * x / SQRT_1;
    }
	function run() public {
	    run(this.repl).withCaller(0x9f6FdC2565CfC9ab8E184753bafc8e94C0F985a0);
	}
    function repl() external {
        uint sp = 16199;
        uint st = 16000;
        uint d1 = generalLog(FIXED_1 * sp / st) * LOG_E_2 / BASE;
        uint cdf = ncdf(d1);
        fmt.printf("d1=%u\n",abi.encode(d1));
        fmt.printf("cdf=%d\n",abi.encode(cdf));
        fmt.printf("FIXED_1=%u\n",abi.encode(FIXED_1));
    }
}