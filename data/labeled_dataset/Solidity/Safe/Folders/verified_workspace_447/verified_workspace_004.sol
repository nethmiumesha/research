pragma solidity ^0.4.18;
import "./OMIToken.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
contract OMITokenLock is Ownable, Pausable {
  using SafeMath for uint256;
  OMIToken public token;
  address public allowanceProvider;
  address public crowdsale;
  bool public crowdsaleFinished = false;
  uint256 public crowdsaleEndTime;
  struct Lock {
    uint256 amount;
    uint256 lockDuration;
    bool released;
    bool revoked;
  }
  struct TokenLockVault {
    address beneficiary;
    uint256 tokenBalance;
    uint256 lockIndex;
    Lock[] locks;
  }
  mapping(address => TokenLockVault) public tokenLocks;
  address[] public lockIndexes;
  uint256 public totalTokensLocked;
  modifier ownerOrCrowdsale () {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }
  event LockedTokens(address indexed beneficiary, uint256 amount, uint256 releaseTime);
  event UnlockedTokens(address indexed beneficiary, uint256 amount);
  event FinishedCrowdsale();
  function OMITokenLock (OMIToken _token) public {
    token = _token;
  }
  function setCrowdsaleAddress (address _crowdsale)
    public
    onlyOwner
    returns (bool)
  {
    crowdsale = _crowdsale;
    return true;
  }
  function setAllowanceAddress (address _allowanceProvider)
    public
    onlyOwner
    returns (bool)
  {
    allowanceProvider = _allowanceProvider;
    return true;
  }
  function finishCrowdsale()
    public
    ownerOrCrowdsale
    whenNotPaused
  {
    require(!crowdsaleFinished);
    crowdsaleFinished = true;
    crowdsaleEndTime = now;
    FinishedCrowdsale();
  }
  function getTokenBalance(address _beneficiary)
    public
    view
    returns (uint)
  {
    return tokenLocks[_beneficiary].tokenBalance;
  }
  function getNumberOfLocks(address _beneficiary)
    public
    view
    returns (uint)
  {
    return tokenLocks[_beneficiary].locks.length;
  }
  function getLockByIndex(address _beneficiary, uint256 _lockIndex)
    public
    view
    returns (uint256 amount, uint256 lockDuration, bool released, bool revoked)
  {
    require(_lockIndex >= 0);
    require(_lockIndex <= tokenLocks[_beneficiary].locks.length.sub(1));
    return (
      tokenLocks[_beneficiary].locks[_lockIndex].amount,
      tokenLocks[_beneficiary].locks[_lockIndex].lockDuration,
      tokenLocks[_beneficiary].locks[_lockIndex].released,
      tokenLocks[_beneficiary].locks[_lockIndex].revoked
    );
  }
  function revokeLockByIndex(address _beneficiary, uint256 _lockIndex)
    public
    onlyOwner
    returns (bool)
  {
    require(_lockIndex >= 0);
    require(_lockIndex <= tokenLocks[_beneficiary].locks.length.sub(1));
    require(!tokenLocks[_beneficiary].locks[_lockIndex].revoked);
    tokenLocks[_beneficiary].locks[_lockIndex].revoked = true;
    return true;
  }
  function lockTokens(address _beneficiary, uint256 _lockDuration, uint256 _tokens)
    external
    ownerOrCrowdsale
    whenNotPaused
  {
    require(_lockDuration >= 0);
    require(_tokens > 0);
    uint256 tokenAllowance = token.allowance(allowanceProvider, address(this));
    require(_tokens.add(totalTokensLocked) <= tokenAllowance);
    TokenLockVault storage lock = tokenLocks[_beneficiary];
    if (lock.beneficiary == 0) {
      lock.beneficiary = _beneficiary;
      lock.lockIndex = lockIndexes.length;
      lockIndexes.push(_beneficiary);
    }
    lock.locks.push(Lock(_tokens, _lockDuration, false, false));
    lock.tokenBalance = lock.tokenBalance.add(_tokens);
    totalTokensLocked = _tokens.add(totalTokensLocked);
    LockedTokens(_beneficiary, _tokens, _lockDuration);
  }
  function releaseTokens()
    public
    whenNotPaused
    returns(bool)
  {
    require(crowdsaleFinished);
    require(_release(msg.sender));
    return true;
  }
  function releaseAll(uint256 _from, uint256 _to)
    external
    whenNotPaused
    onlyOwner
    returns (bool)
  {
    require(_from >= 0);
    require(_from < _to);
    require(_to <= lockIndexes.length);
    require(crowdsaleFinished);
    for (uint256 i = _from; i < _to; i = i.add(1)) {
      address _beneficiary = lockIndexes[i];
      if (_beneficiary == 0x0) {
        continue;
      }
      require(_release(_beneficiary));
    }
    return true;
  }
  function _release(address _beneficiary)
    internal
    whenNotPaused
    returns (bool)
  {
    TokenLockVault memory lock = tokenLocks[_beneficiary];
    require(lock.beneficiary == _beneficiary);
    bool hasUnDueLocks = false;
    bool hasReleasedToken = false;
    for (uint256 i = 0; i < lock.locks.length; i = i.add(1)) {
      Lock memory currentLock = lock.locks[i];
      if (currentLock.released || currentLock.revoked) {
        continue;
      }
      if (crowdsaleEndTime.add(currentLock.lockDuration) >= now) {
        hasUnDueLocks = true;
        continue;
      }
      require(currentLock.amount <= token.allowance(allowanceProvider, address(this)));
      UnlockedTokens(msg.sender, currentLock.amount);
      hasReleasedToken = true;
      tokenLocks[_beneficiary].locks[i].released = true;
      tokenLocks[_beneficiary].tokenBalance = tokenLocks[_beneficiary].tokenBalance.sub(currentLock.amount);
      totalTokensLocked = totalTokensLocked.sub(currentLock.amount);
      assert(token.transferFrom(allowanceProvider, msg.sender, currentLock.amount));
    }
    if (!hasUnDueLocks) {
      delete tokenLocks[msg.sender];
      lockIndexes[lock.lockIndex] = 0x0;
    }
    return hasReleasedToken;
  }
}