pragma solidity ^0.4.24;
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
pragma solidity ^0.4.24;
pragma solidity ^0.4.24;
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) internal balances;
  uint256 internal totalSupply_;
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}
pragma solidity ^0.4.24;
contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }
  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}
pragma solidity ^0.4.24;
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
pragma solidity ^0.4.24;
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
pragma solidity ^0.4.24;
contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
pragma solidity ^0.4.24;
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
pragma solidity ^0.4.24;
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;
  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}
pragma solidity ^0.4.24;
library AddressUtils {
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }
}
pragma solidity 0.4.24;
contract ERC677 is ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    function transferAndCall(address, uint256, bytes) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
}
contract LegacyERC20 {
    function transfer(address _spender, uint256 _value) public;
    function transferFrom(address _owner, address _spender, uint256 _value) public;
}
pragma solidity 0.4.24;
contract IBurnableMintableERC677Token is ERC677 {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _value) public;
    function claimTokens(address _token, address _to) external;
}
pragma solidity 0.4.24;
contract Sacrifice {
    constructor(address _recipient) public payable {
        selfdestruct(_recipient);
    }
}
pragma solidity 0.4.24;
library Address {
    function safeSendValue(address _receiver, uint256 _value) internal {
        if (!_receiver.send(_value)) {
            (new Sacrifice).value(_value)(_receiver);
        }
    }
}
pragma solidity 0.4.24;
library SafeERC20 {
    using SafeMath for uint256;
    function safeTransfer(address _token, address _to, uint256 _value) internal {
        LegacyERC20(_token).transfer(_to, _value);
        assembly {
            if returndatasize {
                returndatacopy(0, 0, 32)
                if iszero(mload(0)) {
                    revert(0, 0)
                }
            }
        }
    }
    function safeTransferFrom(address _token, address _from, uint256 _value) internal {
        LegacyERC20(_token).transferFrom(_from, address(this), _value);
        assembly {
            if returndatasize {
                returndatacopy(0, 0, 32)
                if iszero(mload(0)) {
                    revert(0, 0)
                }
            }
        }
    }
}
pragma solidity 0.4.24;
contract Claimable {
    using SafeERC20 for address;
    modifier validAddress(address _to) {
        require(_to != address(0));
        _;
    }
    function claimValues(address _token, address _to) internal validAddress(_to) {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }
    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        Address.safeSendValue(_to, value);
    }
    function claimErc20Tokens(address _token, address _to) internal {
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        _token.safeTransfer(_to, balance);
    }
}
pragma solidity 0.4.24;
contract ERC677BridgeToken is IBurnableMintableERC677Token, DetailedERC20, BurnableToken, MintableToken, Claimable {
    bytes4 internal constant ON_TOKEN_TRANSFER = 0xa4c0ed36;
    address internal bridgeContractAddr;
    constructor(string _name, string _symbol, uint8 _decimals) public DetailedERC20(_name, _symbol, _decimals) {}
    function bridgeContract() external view returns (address) {
        return bridgeContractAddr;
    }
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        require(AddressUtils.isContract(_bridgeContract));
        bridgeContractAddr = _bridgeContract;
    }
    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }
    function transferAndCall(address _to, uint256 _value, bytes _data) external validRecipient(_to) returns (bool) {
        require(superTransfer(_to, _value));
        emit Transfer(msg.sender, _to, _value, _data);
        if (AddressUtils.isContract(_to)) {
            require(contractFallback(msg.sender, _to, _value, _data));
        }
        return true;
    }
    function getTokenInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (2, 4, 0);
    }
    function superTransfer(address _to, uint256 _value) internal returns (bool) {
        return super.transfer(_to, _value);
    }
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(superTransfer(_to, _value));
        callAfterTransfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(super.transferFrom(_from, _to, _value));
        callAfterTransfer(_from, _to, _value);
        return true;
    }
    function callAfterTransfer(address _from, address _to, uint256 _value) internal {
        if (isBridge(_to)) {
            require(contractFallback(_from, _to, _value, new bytes(0)));
        }
    }
    function isBridge(address _address) public view returns (bool) {
        return _address == bridgeContractAddr;
    }
    function contractFallback(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
        return _to.call(abi.encodeWithSelector(ON_TOKEN_TRANSFER, _from, _value, _data));
    }
    function finishMinting() public returns (bool) {
        revert();
    }
    function renounceOwnership() public onlyOwner {
        revert();
    }
    function claimTokens(address _token, address _to) external onlyOwner {
        claimValues(_token, _to);
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return super.increaseApproval(spender, addedValue);
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}
pragma solidity 0.4.24;
contract PermittableToken is ERC677BridgeToken {
    string public constant version = "1";
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public expirations;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _chainId)
        public
        ERC677BridgeToken(_name, _symbol, _decimals)
    {
        require(_chainId != 0);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        require(_sender != address(0));
        require(_recipient != address(0));
        balances[_sender] = balances[_sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
        if (_sender != msg.sender) {
            uint256 allowedAmount = allowance(_sender, msg.sender);
            if (allowedAmount != uint256(-1)) {
                allowed[_sender][msg.sender] = allowedAmount.sub(_amount);
                emit Approval(_sender, msg.sender, allowed[_sender][msg.sender]);
            } else {
                require(expirations[_sender][msg.sender] == 0 || expirations[_sender][msg.sender] >= _now());
            }
        } else {
        }
        callAfterTransfer(_sender, _recipient, _amount);
        return true;
    }
    function approve(address _to, uint256 _value) public returns (bool result) {
        result = super.approve(_to, _value);
        if (_value == uint256(-1)) {
            delete expirations[msg.sender][_to];
        }
    }
    function increaseAllowance(address _to, uint256 _addedValue) public returns (bool result) {
        result = super.increaseAllowance(_to, _addedValue);
        if (allowed[msg.sender][_to] == uint256(-1)) {
            delete expirations[msg.sender][_to];
        }
    }
    function push(address _to, uint256 _amount) public {
        transferFrom(msg.sender, _to, _amount);
    }
    function pull(address _from, uint256 _amount) public {
        transferFrom(_from, msg.sender, _amount);
    }
    function move(address _from, address _to, uint256 _amount) public {
        transferFrom(_from, _to, _amount);
    }
    function permit(
        address _holder,
        address _spender,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_holder != address(0));
        require(_spender != address(0));
        require(_expiry == 0 || _now() <= _expiry);
        require(_v == 27 || _v == 28);
        require(uint256(_s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, _holder, _spender, _nonce, _expiry, _allowed))
            )
        );
        require(_holder == ecrecover(digest, _v, _r, _s));
        require(_nonce == nonces[_holder]++);
        uint256 amount = _allowed ? uint256(-1) : 0;
        allowed[_holder][_spender] = amount;
        expirations[_holder][_spender] = _allowed ? _expiry : 0;
        emit Approval(_holder, _spender, amount);
    }
    function _now() internal view returns (uint256) {
        return now;
    }
}