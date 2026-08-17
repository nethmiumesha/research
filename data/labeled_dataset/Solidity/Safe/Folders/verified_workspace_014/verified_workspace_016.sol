pragma solidity ^0.4.24;
import "../token/ERC20/ERC20Pausable.sol";
import "./PauserRoleMock.sol";
contract ERC20PausableMock is ERC20Pausable, PauserRoleMock {
  constructor(address initialAccount, uint initialBalance) public {
    _mint(initialAccount, initialBalance);
  }
}