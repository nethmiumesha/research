pragma solidity >=0.4.21 <0.6.0;
contract IPriceOracle{
  function getPrice() public view returns(uint256);
}