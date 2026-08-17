pragma solidity ^0.4.24;
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is ERC20 {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    require(_to != address(0));
    require (_value <= _allowance);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
contract schwabenfitness is StandardToken {
  string public constant name = "schwabenfitness";
  string public constant symbol = "sche";
  uint8 public constant decimals = 0;
  function schwabenfitness() public {
    totalSupply = 333000000;
    balances[msg.sender] = totalSupply;
  }
}