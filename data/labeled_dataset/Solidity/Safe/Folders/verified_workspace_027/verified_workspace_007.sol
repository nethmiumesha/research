pragma solidity 0.5.8;
import "../interfaces/IOracle.sol";
contract MockOracle is IOracle {
    address public currency;
    bytes32 public currencySymbol;
    bytes32 public denominatedCurrency;
    uint256 public price;
    constructor(address _currency, bytes32 _currencySymbol, bytes32 _denominatedCurrency, uint256 _price) public {
        currency = _currency;
        currencySymbol = _currencySymbol;
        denominatedCurrency = _denominatedCurrency;
        price = _price;
    }
    function changePrice(uint256 _price) external {
        price = _price;
    }
    function getCurrencyAddress() external view returns(address) {
        return currency;
    }
    function getCurrencySymbol() external view returns(bytes32) {
        return currencySymbol;
    }
    function getCurrencyDenominated() external view returns(bytes32) {
        return denominatedCurrency;
    }
    function getPrice() external returns(uint256) {
        return price;
    }
}