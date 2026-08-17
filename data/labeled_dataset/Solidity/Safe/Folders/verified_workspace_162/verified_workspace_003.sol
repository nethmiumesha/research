pragma solidity ^0.4.18;
contract IERC20 {
  function balanceOf(address who) public view returns (uint256);
  function allowance(address owner, address spender) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract PolyToken is IERC20 {
  using SafeMath for uint256;
  string public name = 'Polymath';
  string public symbol = 'POLY';
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
  uint256 public totalSupply = 1000000000 * decimalFactor;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  function PolyToken(address _polyDistributionContractAddress) public {
    balances[_polyDistributionContractAddress] = totalSupply;
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
contract PolyDistribution is Ownable {
  using SafeMath for uint256;
  PolyToken public POLY;
  uint256 private constant decimals = 10**uint256(18);
  enum AllocationType { PRESALE, FOUNDER, AIRDROP, ADVISOR, BONUS, RESERVE }
  uint256 public AVAILABLE_TOTAL_SUPPLY    = 1000000000 * decimals;
  uint256 public AVAILABLE_PRESALE_SUPPLY  = 240000000 * decimals;
  uint256 public AVAILABLE_FOUNDER_SUPPLY  = 150000000 * decimals;
  uint256 public AVAILABLE_AIRDROP_SUPPLY  = 10000000 * decimals;
  uint256 public AVAILABLE_ADVISOR_SUPPLY  = 25000000 * decimals;
  uint256 public AVAILABLE_BONUS_SUPPLY    = 80000000 * decimals;
  uint256 public AVAILABLE_RESERVE_SUPPLY  = 495000000 * decimals;
  uint256 public grandTotalAllocated = 0;
  uint256 public grandTotalClaimed = 0;
  uint256 public startTime;
  struct Allocation {
    uint8 AllocationSupply;
    uint256 endCliff;
    uint256 endVesting;
    uint256 totalAllocated;
    uint256 amountClaimed;
  }
  mapping (address => Allocation) public allocations;
  event LogNewAllocation(address _recipient, uint8 _fromSupply, uint256 _totalAllocated, uint256 _grandTotalAllocated);
  event LogPolyClaimed(address _recipient, uint8 _fromSupply, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
    function PolyDistribution(uint256 _startTime) public {
      require(_startTime >= now);
      require(AVAILABLE_TOTAL_SUPPLY == AVAILABLE_PRESALE_SUPPLY.add(AVAILABLE_FOUNDER_SUPPLY).add(AVAILABLE_AIRDROP_SUPPLY).add(AVAILABLE_ADVISOR_SUPPLY).add(AVAILABLE_BONUS_SUPPLY).add(AVAILABLE_RESERVE_SUPPLY));
      startTime = _startTime;
      POLY = new PolyToken(this);
    }
  function setAllocation (address _recipient, uint256 _totalAllocated, uint8 _supply) onlyOwner public {
    require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);
    require(_supply >= 0 && _supply <= 5);
    require(_recipient != address(0));
    if (_supply == 0) {
      AVAILABLE_PRESALE_SUPPLY = AVAILABLE_PRESALE_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.PRESALE), 0, 0, _totalAllocated, 0);
    } else if (_supply == 1) {
      AVAILABLE_FOUNDER_SUPPLY = AVAILABLE_FOUNDER_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.FOUNDER), startTime + 1 years, startTime + 4 years, _totalAllocated, 0);
    } else if (_supply == 2) {
      AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.AIRDROP), 0, 0, _totalAllocated, 0);
    } else if (_supply == 3) {
      AVAILABLE_ADVISOR_SUPPLY = AVAILABLE_ADVISOR_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.ADVISOR), startTime + 212 days, 0, _totalAllocated, 0);
    } else if (_supply == 4) {
      AVAILABLE_BONUS_SUPPLY = AVAILABLE_BONUS_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BONUS), startTime + 1 years, startTime + 4 years, _totalAllocated, 0);
    } else if (_supply == 5) {
      AVAILABLE_RESERVE_SUPPLY = AVAILABLE_RESERVE_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.RESERVE), startTime + 182 days, startTime + 4 years, _totalAllocated, 0);
    }
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(_totalAllocated);
    grandTotalAllocated = grandTotalAllocated.add(_totalAllocated);
    LogNewAllocation(_recipient, _supply, _totalAllocated, grandTotalAllocated);
  }
  function transferTokens (address _recipient) public {
    require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated);
    require(now >= allocations[_recipient].endCliff);
    uint256 newAmountClaimed;
    if (allocations[_recipient].endVesting > now) {
      newAmountClaimed = allocations[_recipient].totalAllocated.mul(now.sub(startTime)).div(allocations[_recipient].endVesting.sub(startTime));
    } else {
      newAmountClaimed = allocations[_recipient].totalAllocated;
    }
    uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_recipient].amountClaimed);
    allocations[_recipient].amountClaimed = newAmountClaimed;
    POLY.transfer(_recipient, tokensToTransfer);
    grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
    LogPolyClaimed(_recipient, allocations[_recipient].AllocationSupply, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
  }
  function refundTokens(address _recipient, address _token) public onlyOwner {
    require(_token != address(this));
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(_recipient, balance);
  }
}