pragma solidity ^0.4.25;
contract owned {
	address public owner;
	function owned() public {
	owner = msg.sender;
	}
	modifier onlyOwner {
	require(msg.sender == owner);
	_;
	}
	function transferOwnership(address newOwner) onlyOwner public {
	owner = newOwner;
	}
}
contract TokenERC20 {
	using SafeMath for uint256;
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Burn(address indexed from, uint256 value);
	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);
		name = tokenName;
		symbol = tokenSymbol;
	}
	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);
		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}
	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}
	function burn(uint256 _value) public returns (bool success) {
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(msg.sender, _value);
		return true;
	}
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		balanceOf[_from] = balanceOf[_from].sub(_value);
		allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_from, _value);
		return true;
	}
}
contract Token is owned, TokenERC20  {
	uint256 _initialSupply=420000000;
	string _tokenName="testdist";
	string _tokenSymbol="tsdt";
	address wallet1 = 0x8012Eb27b9F5Ac2b74A975a100F60d2403365871;
	uint256 public startTime;
	mapping (address => bool) public frozenAccount;
	function Token( ) TokenERC20(_initialSupply, _tokenName, _tokenSymbol) public {
		startTime = now;
		balanceOf[wallet1] = totalSupply;
	}
	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);
		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}
}