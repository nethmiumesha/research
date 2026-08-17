pragma solidity ^0.8.6;
import "../../contracts/CErc20.sol";
import "../../contracts/CToken.sol";
import "../../contracts/PriceOracle.sol";
interface V1PriceOracleInterface {
    function assetPrices(address asset) external view returns (uint);
}
contract PriceOracleProxy is PriceOracle {
    V1PriceOracleInterface public v1PriceOracle;
    address public guardian;
    address public cEthAddress;
    address public cUsdcAddress;
    address public cUsdtAddress;
    address public cSaiAddress;
    address public cDaiAddress;
    address public constant usdcOracleKey = address(1);
    address public constant daiOracleKey = address(2);
    uint public saiPrice;
    constructor(address guardian_,
                address v1PriceOracle_,
                address cEthAddress_,
                address cUsdcAddress_,
                address cSaiAddress_,
                address cDaiAddress_,
                address cUsdtAddress_) {
        guardian = guardian_;
        v1PriceOracle = V1PriceOracleInterface(v1PriceOracle_);
        cEthAddress = cEthAddress_;
        cUsdcAddress = cUsdcAddress_;
        cSaiAddress = cSaiAddress_;
        cDaiAddress = cDaiAddress_;
        cUsdtAddress = cUsdtAddress_;
    }
    function getUnderlyingPrice(CToken cToken) override public view returns (uint) {
        address cTokenAddress = address(cToken);
        if (cTokenAddress == cEthAddress) {
            return 1e18;
        }
        if (cTokenAddress == cUsdcAddress || cTokenAddress == cUsdtAddress) {
            return v1PriceOracle.assetPrices(usdcOracleKey);
        }
        if (cTokenAddress == cDaiAddress) {
            return v1PriceOracle.assetPrices(daiOracleKey);
        }
        if (cTokenAddress == cSaiAddress) {
            return saiPrice > 0 ? saiPrice : v1PriceOracle.assetPrices(daiOracleKey);
        }
        address underlying = CErc20(cTokenAddress).underlying();
        return v1PriceOracle.assetPrices(underlying);
    }
    function setSaiPrice(uint price) public {
        require(msg.sender == guardian, "only guardian may set the SAI price");
        require(saiPrice == 0, "SAI price may only be set once");
        require(price < 0.1e18, "SAI price must be < 0.1 ETH");
        saiPrice = price;
    }
}