pragma solidity ^0.4.12;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
contract Recoverable is Ownable {
  function Recoverable() {
  }
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return token.balanceOf(this);
  }
}