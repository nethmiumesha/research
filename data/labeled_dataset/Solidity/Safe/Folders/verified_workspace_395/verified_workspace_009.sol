pragma solidity ^0.4.8;
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
contract FractionalERC20 is ERC20 {
  uint public decimals;
}