pragma solidity 0.4.25;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
contract InvalidReturnTokenMock {
  using SafeMath for uint;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  uint256 public decimals;
  string public name;
  string public symbol;
  uint256 public totalSupply;
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
  constructor(
    address initialAccount,
    uint256 initialBalance,
    string _name,
    string _symbol,
    uint256 _decimals)
    public
  {
    balances[initialAccount] = initialBalance;
    totalSupply = initialBalance;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
  function totalSupply() external view returns (uint256) {
    return totalSupply;
  }
  function transfer(
    address _to,
    uint256 _value
  )
    external
    returns(uint256)
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return 4;
  }
  function balanceOf(address _owner) external view returns (uint256) {
    return balances[_owner];
  }
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    external
    returns(uint256)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return 4;
  }
  function approve(
    address _spender,
    uint256 _value
  )
    external
    returns(uint256)
  {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return 4;
  }
  function allowance(
    address _owner,
    address _spender
   )
    external
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    external
    returns(uint256)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return 4;
  }
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    external
    returns(uint256)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return 4;
  }
}