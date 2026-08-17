pragma solidity 0.6.12;
import "../utility/Utils.sol";
import "../utility/SafeMath.sol";
contract NonStandardToken is Utils {
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    constructor(uint256 _supply)
        internal
    {
        totalSupply = _supply;
        balanceOf[msg.sender] = _supply;
    }
    function _transfer(address _to, uint256 _value)
        internal
        validAddress(_to)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }
    function _transferFrom(address _from, address _to, uint256 _value)
        internal
        validAddress(_from)
        validAddress(_to)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
    function _approve(address _spender, uint256 _value)
        internal
        validAddress(_spender)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
}
contract NonStandardTokenDetailed is NonStandardToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply)
        internal
        NonStandardToken(_supply)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}
contract TestNonStandardToken is NonStandardTokenDetailed {
    bool public ok;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) public
        NonStandardTokenDetailed(_name, _symbol, _decimals, _supply) {
        set(true);
    }
    function set(bool _ok) public {
        ok = _ok;
    }
    function approve(address _spender, uint256 _value) public {
        _approve(_spender, _value);
        require(ok);
    }
    function transfer(address _to, uint256 _value) public {
        _transfer(_to, _value);
        require(ok);
    }
    function transferFrom(address _from, address _to, uint256 _value) public {
        _transferFrom(_from, _to, _value);
        require(ok);
    }
}
contract TestNonStandardTokenWithoutDecimals is NonStandardToken {
    string public name;
    string public symbol;
    constructor(string memory _name, string memory _symbol, uint256 _supply) public
        NonStandardToken(_supply) {
        name = _name;
        symbol = _symbol;
    }
    function approve(address _spender, uint256 _value) public {
        _approve(_spender, _value);
    }
    function transfer(address _to, uint256 _value) public {
        _transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public {
        _transferFrom(_from, _to, _value);
    }
}
contract TestStandardToken is NonStandardTokenDetailed {
    bool public ok;
    bool public ret;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) public
        NonStandardTokenDetailed(_name, _symbol, _decimals, _supply) {
        set(true, true);
    }
    function set(bool _ok, bool _ret) public {
        ok = _ok;
        ret = _ret;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(_spender, _value);
        require(ok);
        return ret;
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(_to, _value);
        require(ok);
        return ret;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transferFrom(_from, _to, _value);
        require(ok);
        return ret;
    }
}