pragma solidity 0.6.11;
import "../Interfaces/IPriceFeed.sol";
contract PriceFeedTestnet is IPriceFeed {
    uint256 private _price = 200 * 1e18;
    function getPrice() external view override returns (uint256) {
        return _price;
    }
    function setPrice(uint256 price) external returns (bool) {
        _price = price;
        return true;
    }
}