pragma solidity 0.4.25;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
contract NoXferReturnTokenMock {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  uint256 public decimals;
  string public name;
  string public symbol;
  uint256 public totalSupply;
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
  function transfer(address _to, uint256 _value) external {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
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
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
  }
  function approve(address _spender, uint256 _value) external {
    allowed[msg.sender][_spender] = _value;
  }
}