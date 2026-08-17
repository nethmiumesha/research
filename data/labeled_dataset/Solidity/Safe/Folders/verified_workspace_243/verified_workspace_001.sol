pragma solidity 0.4.25;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
contract BadTokenMock is ERC20 {
  uint256 constant public decimals = 18;
  string public name;
  string public symbol;
  uint256 public totalSupply;
  constructor(
    address initialAccount,
    uint256 initialBalance,
    string _name,
    string _symbol)
    public
  {
    _mint(initialAccount, initialBalance);
    name = _name;
    symbol = _symbol;
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
}