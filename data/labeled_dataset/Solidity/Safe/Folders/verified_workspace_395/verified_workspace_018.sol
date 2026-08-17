pragma solidity ^0.4.14;
import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "./Recoverable.sol";
contract StandardTokenExt is StandardToken, Recoverable {
  function isToken() public constant returns (bool weAre) {
    return true;
  }
}