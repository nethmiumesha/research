pragma solidity ^0.4.18;
import './SafeMath.sol';
import './Owned.sol';
import './Validating.sol';
import './StandardToken.sol';
contract Fee is Owned, Validating, StandardToken {
  event Burn(address indexed from, uint256 value);
  string public name;
  uint8 public decimals;
  string public symbol;
  uint256 public feeInCirculation;
  string public version = 'F0.1';
  address public minter;
  modifier onlyMinter {
    require(msg.sender == minter);
    _;
  }
  function Fee(
  address[] _owners,
  string _tokenName,
  uint8 _decimalUnits,
  string _tokenSymbol
  )
  public
  notEmpty(_tokenName)
  notEmpty(_tokenSymbol)
  {
    setOwners(_owners);
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
  }
  function setMinter(address _minter) external onlyOwner validAddress(_minter) {
    minter = _minter;
  }
  function burnTokens(uint _value) public notZero(_value) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    feeInCirculation = SafeMath.sub(feeInCirculation, _value);
    Burn(msg.sender, _value);
  }
  function sendTokens(address _to, uint _value) public onlyMinter validAddress(_to) notZero(_value) {
    balances[_to] = SafeMath.add(balances[_to], _value);
    feeInCirculation = SafeMath.add(feeInCirculation, _value);
    Transfer(msg.sender, _to, _value);
  }
}