pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ProxyClones/OwnableForClones.sol";
contract DACVesting is OwnableForClones {
  IERC20 public token;
  uint256 public startTime;
  uint256 public duration;
  uint256 public exp;
  uint256 public cliff;
  uint256 public cliffDelay;
  mapping(address => uint256) private totalDeposit;
  mapping(address => uint256) private drainedAmount;
  event TokensDeposited(address indexed beneficiary, uint256 indexed amount);
  event TokensRetrieved(address indexed beneficiary, uint256 indexed amount);
  event VestingDecreased(address indexed beneficiary, uint256 indexed amount);
  function initialize
   (
    address _token,
    address _owner,
    uint256 _startInDays,
    uint256 _durationInDays,
    uint256 _cliffInTenThousands,
    uint256 _cliffDelayInDays,
    uint256 _exp
   )
    external initializer
   {
    __Ownable_init();
    token = IERC20(_token);
    startTime = block.timestamp + _startInDays * 86400;
    duration = _durationInDays * 86400;
    cliff = _cliffInTenThousands;
    cliffDelay = _cliffDelayInDays * 86400;
    exp = _exp;
    if (_owner == address(0)) {
      renounceOwnership();
    }else {
      transferOwnership(_owner);
    }
  }
  function depositForCrowd(address[] memory _recipient, uint256[] memory _amount) external {
    require(_recipient.length == _amount.length, "lengths must match");
    for (uint256 i = 0; i < _recipient.length; i++) {
      _rawDeposit(msg.sender, _recipient[i], _amount[i]);
    }
  }
  function depositFor(address _recipient, uint256 _amount) external {
    _rawDeposit(msg.sender, _recipient, _amount);
  }
  function depositAllFor(address _recipient) external {
    _rawDeposit(msg.sender, _recipient, token.balanceOf(_recipient));
  }
  function retrieve() external {
    uint256 amount = getRetrievableAmount(msg.sender);
    require(amount != 0, "nothing to retrieve");
    _rawRetrieve(msg.sender, amount);
  }
  function retrieveFor(address[] memory accounts) external {
    for (uint256 i = 0; i < accounts.length; i++) {
      uint256 amount = getRetrievableAmount(accounts[i]);
      _rawRetrieve(accounts[i], amount);
    }
  }
  function decreaseVesting(address _account, uint256 amount) external onlyOwner {
    require(drainedAmount[_account] <= totalDeposit[_account] - amount, "deposit has to be >= drainedAmount");
    totalDeposit[_account] -= amount;
    emit VestingDecreased(_account, amount);
  }
  function getTotalDeposit(address _account) external view returns(uint256) {
    return totalDeposit[_account];
  }
  function getTotalVestingBalance(address _account) external view returns(uint256) {
    return totalDeposit[_account] - drainedAmount[_account];
  }
  function getRetrievablePercentage() external view returns(uint256) {
    return _getPercentage() / 100;
  }
  function balanceOf(address account) external view returns(uint256) {
    return token.balanceOf(account) + totalDeposit[account] - drainedAmount[account];
  }
  function getRetrievableAmount(address _account) public view returns(uint256) {
    if(_getPercentage() * totalDeposit[_account] / 1e4 > drainedAmount[_account]) {
      return (_getPercentage() * totalDeposit[_account] / 1e4) - drainedAmount[_account];
    }else {
      return 0;
    }
  }
  function _rawDeposit(address _from, address _for, uint256 _amount) private {
    require(token.transferFrom(_from, address(this), _amount));
    totalDeposit[_for] += _amount;
    emit TokensDeposited(_for, _amount);
  }
  function _rawRetrieve(address account, uint256 amount) private {
    drainedAmount[account] += amount;
    token.transfer(account, amount);
    assert(drainedAmount[account] <= totalDeposit[account]);
    emit TokensRetrieved(account, amount);
  }
  function _getPercentage() private view returns(uint256) {
    if (cliff == 0) {
      return _getPercentageNoCliff();
    }else {
      return _getPercentageWithCliff();
    }
  }
  function _getPercentageNoCliff() private view returns(uint256) {
    if (startTime > block.timestamp) {
      return 0;
    }else if (startTime + duration > block.timestamp) {
      return (1e4 * (block.timestamp - startTime)**exp) / duration**exp;
    }else {
      return 1e4;
    }
  }
  function _getPercentageWithCliff() private view returns(uint256) {
    if (block.timestamp + cliffDelay < startTime) {
      return 0;
    }else if (block.timestamp < startTime) {
      return cliff;
    }else if (1e4 * (block.timestamp - startTime)**exp / duration**exp + cliff < 1e4) {
      return (1e4 * (block.timestamp - startTime)**exp / duration**exp) + cliff;
    }else {
      return 1e4;
    }
  }
}