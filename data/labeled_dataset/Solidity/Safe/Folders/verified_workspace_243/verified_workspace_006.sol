pragma solidity 0.4.25;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
contract StandardTokenWithFeeMock {
  using SafeMath for uint256;
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
  uint256 constant public decimals = 18;
  string public name;
  string public symbol;
  uint256 public fee;
  mapping (address => uint256) public _balances;
  mapping (address => mapping (address => uint256)) public _allowed;
  uint256 public _totalSupply;
  constructor(
    address initialAccount,
    uint256 initialBalance,
    string _name,
    string _symbol,
    uint256 _fee)
    public
  {
    _balances[initialAccount] = initialBalance;
    _totalSupply = initialBalance;
    name = _name;
    symbol = _symbol;
    fee = _fee;
  }
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
    require(_to != address(0), "to nonnull");
    require(_value <= _balances[_from], "less than from");
    require(_value <= _allowed[_from][msg.sender], "value less than allowed");
    uint256 netValueMinusFee = _value.sub(fee);
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(netValueMinusFee);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function transfer(address _to, uint256 _value) external returns (bool) {
    require(_to != address(0));
    require(_value <= _balances[msg.sender]);
    uint256 netValuePlusFee = _value.add(fee);
    _balances[msg.sender] = _balances[msg.sender].sub(netValuePlusFee);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function setFee(uint256 _fee) external returns (bool) {
    fee = _fee;
    return true;
  }
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) external view returns (uint256) {
    return _balances[owner];
  }
  function allowance(
    address owner,
    address spender
   )
    external
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }
  function approve(address spender, uint256 value) external returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    external
    returns (bool)
  {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    external
    returns (bool)
  {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
}