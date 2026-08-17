pragma solidity 0.4.23;
import "./EthPriceDependent.sol";
contract EthPriceDependentForICO is EthPriceDependent {
    function priceExpired() public view returns (bool) {
        return (getTime() > m_ETHPriceLastUpdate + m_ETHPriceLifetime);
    }
    uint public m_ETHPriceLifetime = 60*60*12;
}