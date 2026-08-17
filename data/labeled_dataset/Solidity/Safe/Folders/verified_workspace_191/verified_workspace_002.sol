pragma solidity 0.5.9;
contract ERC677Receiver {
  function onTokenTransfer(address _from, uint _value, bytes calldata _data) external returns(bool);
}
contract ERC20Basic {
  event Transfer(address indexed from, address indexed to, uint256 value);
  function totalSupply() public view returns(uint256);
  function balanceOf(address who) public view returns(uint256);
  function transfer(address to, uint256 value) public returns(bool);
}
contract ERC20 is ERC20Basic {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function allowance(address owner, address spender) public view returns(uint256);
  function transferFrom(address from, address to, uint256 value) public returns(bool);
  function approve(address spender, uint256 value) public returns(bool);
}
contract ERC677 is ERC20 {
  event Transfer(address indexed from, address indexed to, uint value, bytes data);
  function transferAndCall(address, uint, bytes calldata) external returns(bool);
}
contract IBurnableMintableERC677Token is ERC677 {
  function mint(address, uint256) public returns(bool);
  function burn(uint256 _value) public;
  function claimTokens(address _token, address payable _to) public;
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}
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
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;
  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
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
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
contract ERC677BridgeToken is
  IBurnableMintableERC677Token,
  DetailedERC20,
  BurnableToken,
  MintableToken
{
  address public bridgeContract;
  event ContractFallbackCallFailed(address from, address to, uint value);
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public DetailedERC20(
    _name,
    _symbol,
    _decimals
  ) {}
  function setBridgeContract(address _bridgeContract) onlyOwner public {
    require(_bridgeContract != address(0) && isContract(_bridgeContract));
    bridgeContract = _bridgeContract;
  }
  modifier validRecipient(address _recipient) {
    require(_recipient != address(0) && _recipient != address(this));
    _;
  }
  function transferAndCall(
    address _to,
    uint _value,
    bytes calldata _data
  )
    external
    validRecipient(_to)
    returns(bool)
  {
    require(superTransfer(_to, _value));
    emit Transfer(msg.sender, _to, _value, _data);
    if (isContract(_to)) {
      require(contractFallback(_to, _value, _data));
    }
    return true;
  }
  function getTokenInterfacesVersion() public pure returns(uint64 major, uint64 minor, uint64 patch) {
    return (2, 0, 0);
  }
  function superTransfer(address _to, uint256 _value) internal returns(bool)
  {
    return super.transfer(_to, _value);
  }
  function transfer(address _to, uint256 _value) public returns (bool)
  {
    require(superTransfer(_to, _value));
    if (isContract(_to) && !contractFallback(_to, _value, new bytes(0))) {
      if (_to == bridgeContract) {
        revert();
      } else {
        emit ContractFallbackCallFailed(msg.sender, _to, _value);
      }
    }
    return true;
  }
  function contractFallback(
    address _to,
    uint _value,
    bytes memory _data
  )
    private
    returns(bool)
  {
    (bool success,) = _to.call(
      abi.encodeWithSignature("onTokenTransfer(address,uint256,bytes)", msg.sender, _value, _data)
    );
    return success;
  }
  function isContract(address _addr)
    internal
    view
    returns (bool)
  {
    uint length;
    assembly { length := extcodesize(_addr) }
    return length > 0;
  }
  function finishMinting() public returns (bool) {
    revert();
  }
  function renounceOwnership() public onlyOwner {
    revert();
  }
  function claimTokens(address _token, address payable _to) public onlyOwner {
    require(_to != address(0));
    if (_token == address(0)) {
      _to.transfer(address(this).balance);
      return;
    }
    DetailedERC20 token = DetailedERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    require(token.transfer(_to, balance));
  }
}
contract ERC677BridgeTokenRewardable is ERC677BridgeToken {
  address public blockRewardContract;
  address public stakingContract;
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public ERC677BridgeToken(
    _name,
    _symbol,
    _decimals
  ) {}
  modifier onlyBlockRewardContract() {
    require(msg.sender == blockRewardContract);
    _;
  }
  modifier onlyStakingContract() {
    require(msg.sender == stakingContract);
    _;
  }
  function setBlockRewardContract(address _blockRewardContract) onlyOwner public {
    require(_blockRewardContract != address(0) && isContract(_blockRewardContract));
    blockRewardContract = _blockRewardContract;
  }
  function setStakingContract(address _stakingContract) onlyOwner public {
    require(_stakingContract != address(0) && isContract(_stakingContract));
    stakingContract = _stakingContract;
  }
  function mintReward(address[] calldata _receivers, uint256[] calldata _rewards) external onlyBlockRewardContract {
    for (uint256 i = 0; i < _receivers.length; i++) {
      uint256 amount = _rewards[i];
      if (amount == 0) continue;
      address to = _receivers[i];
      totalSupply_ = totalSupply_.add(amount);
      balances[to] = balances[to].add(amount);
      emit Mint(to, amount);
      emit Transfer(address(0), to, amount);
    }
  }
  function stake(address _staker, uint256 _amount) external onlyStakingContract {
    require(_amount <= balances[_staker]);
    balances[_staker] = balances[_staker].sub(_amount);
    balances[stakingContract] = balances[stakingContract].add(_amount);
    emit Transfer(_staker, stakingContract, _amount);
  }
  function withdraw(address _staker, uint256 _amount) external onlyStakingContract {
    require(_amount <= balances[stakingContract]);
    balances[stakingContract] = balances[stakingContract].sub(_amount);
    balances[_staker] = balances[_staker].add(_amount);
    emit Transfer(stakingContract, _staker, _amount);
  }
  function transfer(address _to, uint256 _value) public returns(bool) {
    require(_to != stakingContract);
    return super.transfer(_to, _value);
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    require(_to != stakingContract);
    return super.transferFrom(_from, _to, _value);
  }
}
contract ERC677BridgeTokenRewardableMock is ERC677BridgeTokenRewardable {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public ERC677BridgeTokenRewardable(
    _name,
    _symbol,
    _decimals
  ) {
  }
}