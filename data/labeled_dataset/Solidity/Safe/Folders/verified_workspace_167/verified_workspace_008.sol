pragma solidity 0.5.4;
pragma experimental ABIEncoderV2;
import { IPriceOracle } from "../protocol/interfaces/IPriceOracle.sol";
import { Monetary } from "../protocol/lib/Monetary.sol";
contract TestPriceOracle is IPriceOracle {
    mapping (address => uint256) public g_prices;
    function setPrice(
        address token,
        uint256 price
    )
        external
    {
        g_prices[token] = price;
    }
    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory)
    {
        return Monetary.Price({
            value: g_prices[token]
        });
    }
}