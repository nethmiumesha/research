pragma solidity 0.5.11;
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IMinMaxOracle.sol";
contract MockOracle is IPriceOracle, IMinMaxOracle {
    mapping(bytes32 => uint256) prices;
    mapping(bytes32 => uint256[]) pricesMinMax;
    uint256 ethMin;
    uint256 ethMax;
    function price(string calldata symbol) external view returns (uint256) {
        return prices[keccak256(abi.encodePacked(symbol))];
    }
    function setPrice(string calldata symbol, uint256 _price) external {
        prices[keccak256(abi.encodePacked(symbol))] = _price;
    }
    function setEthPriceMinMax(uint256 _min, uint256 _max) external {
        ethMin = _min;
        ethMax = _max;
    }
    function setTokPriceMinMax(
        string calldata symbol,
        uint256 _min,
        uint256 _max
    ) external {
        pricesMinMax[keccak256(abi.encodePacked(symbol))] = [_min, _max];
    }
    function priceMin(string calldata symbol) external returns (uint256) {
        uint256[] storage pMinMax = pricesMinMax[keccak256(
            abi.encodePacked(symbol)
        )];
        return (pMinMax[0] * ethMin) / 1e6;
    }
    function priceMax(string calldata symbol) external returns (uint256) {
        uint256[] storage pMinMax = pricesMinMax[keccak256(
            abi.encodePacked(symbol)
        )];
        return (pMinMax[1] * ethMax) / 1e6;
    }
}