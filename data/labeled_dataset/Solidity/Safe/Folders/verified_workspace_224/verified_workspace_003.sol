pragma solidity 0.4.23;
import '../BoomstarterPresale.sol';
contract BoomstarterPresaleTestHelper is BoomstarterPresale {
    function BoomstarterPresaleTestHelper(address[] _owners, address _token,
                                          address _beneficiary, bool _production)
        public
        BoomstarterPresale(_owners, _token, _beneficiary, _production)
    {
        m_ETHPriceUpdateInterval = 5;
        c_MinInvestmentInCents = 1 * 100;
        m_ETHPriceInCents = 300*100;
        m_leeway = 0;
    }
    function setTime(uint time) public {
        m_time = time;
    }
    function getTime() internal view returns (uint) {
        return m_time;
    }
    function setPriceRiseTokenAmount(uint amount) public {
      c_priceRiseTokenAmount = amount;
    }
    function setMaximumTokensSold(uint amount) public {
      c_maximumTokensSold = amount;
    }
    uint public m_time;
}