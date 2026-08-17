pragma solidity ^0.4.12;
import "./PricingStrategy.sol";
import "./SafeMathLib.sol";
contract FlatPricing is PricingStrategy {
  using SafeMathLib for uint;
  uint public oneTokenInWei;
  function FlatPricing(uint _oneTokenInWei) {
    require(_oneTokenInWei > 0);
    oneTokenInWei = _oneTokenInWei;
  }
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.times(multiplier) / oneTokenInWei;
  }
}