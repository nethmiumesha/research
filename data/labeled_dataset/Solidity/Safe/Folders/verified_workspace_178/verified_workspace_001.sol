pragma solidity ^0.6.6;
struct RatPrice {
    uint numerator;
    uint denominator;
}
library DecFloat32 {
    uint32 constant MantissaMask = (1<<27) - 1;
    uint32 constant MaxMantissa = 9999_9999;
    uint32 constant MinMantissa = 1000_0000;
    uint32 constant MinPrice = MinMantissa;
    uint32 constant MaxPrice = (31<<27)|MaxMantissa;
    function powSmall(uint32 i) internal pure returns (uint) {
        uint X = 2695994666777834996822029817977685892750687677375768584125520488993233305610;
        return (X >> (32*i)) & ((1<<32)-1);
    }
    function powBig(uint32 i) internal pure returns (uint) {
        uint Y = 3402823669209384634633746076162356521930955161600000001;
        return (Y >> (64*i)) & ((1<<64)-1);
    }
    function expandPrice(uint32 price32) internal pure returns (RatPrice memory) {
        uint s = price32&((1<<27)-1);
        uint32 a = price32 >> 27;
        RatPrice memory price;
        if(a >= 24) {
            uint32 b = a - 24;
            price.numerator = s * powSmall(b);
            price.denominator = 1;
        } else if(a == 23) {
            price.numerator = s;
            price.denominator = 1;
        } else {
            uint32 b = 22 - a;
            price.numerator = s;
            price.denominator = powSmall(b&0x7) * powBig(b>>3);
        }
        return price;
    }
    function getExpandPrice(uint price) internal pure returns(uint numerator, uint denominator) {
        uint32 m = uint32(price) & DecFloat32.MantissaMask;
        require(DecFloat32.MinMantissa <= m && m <= DecFloat32.MaxMantissa, "Invalid Price");
        RatPrice memory actualPrice = DecFloat32.expandPrice(uint32(price));
        return (actualPrice.numerator, actualPrice.denominator);
    }
}