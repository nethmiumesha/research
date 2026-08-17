pragma solidity 0.8.25;
interface IPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }
    function getPriceUnsafe(bytes32 id) external view returns (Price memory price);
}
contract MUSDOracle {
    address public constant pyth = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
    bytes32 public constant musdPythId = 0x0617a9b725011a126a2b9fd53563f4236501f32cf76d877644b943394606c6de;
    function latestAnswer() external view returns (int256) {
        IPyth.Price memory p = IPyth(pyth).getPriceUnsafe(musdPythId);
        if (p.publishTime + 24 hours < block.timestamp) {
            revert("Stale price");
        }
        int32 delta = -p.expo - 8;
        if (delta == 0) {
            return p.price;
        } else if (delta > 0) {
            return p.price / int256(10 ** uint32(delta));
        } else {
            return p.price * int256(10 ** uint32(-delta));
        }
    }
}