pragma solidity ^0.4.18;
import './SafeMath.sol';
import './Owned.sol';
import './Validating.sol';
import './Token.sol';
import './Fee.sol';
contract Stake is Owned, Validating {
  using SafeMath for uint;
  event StakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock);
  event RedeemEvent(address indexed user, uint levs, uint feeEarned, uint startBlock, uint endBlock);
  event FeeCalculated(uint feeCalculated, uint feeReceived, uint weiReceived, uint startBlock, uint endBlock);
  event StakingInterval(uint startBlock, uint endBlock);
  mapping (address => uint) public levBlocks;
  mapping (address => uint) public stakes;
  uint public totalLevs;
  uint public totalLevBlocks;
  uint public weiPerFee;
  uint public feeForTheStakingInterval;
  Token public levToken;
  Fee public feeToken;
  uint public startBlock;
  uint public endBlock;
  address public wallet;
  bool public feeCalculated = false;
  modifier isStaking {
    require(startBlock <= block.number && block.number < endBlock);
    _;
  }
  modifier isDoneStaking {
    require(block.number >= endBlock);
    _;
  }
  function() public payable {
  }
  function Stake(
  address[] _owners,
  address _operator,
  address _wallet,
  uint _weiPerFee,
  address _levToken
  ) public
  validAddress(_wallet)
  validAddress(_operator)
  validAddress(_levToken)
  notZero(_weiPerFee)
  {
    setOwners(_owners);
    operator = _operator;
    wallet = _wallet;
    weiPerFee = _weiPerFee;
    levToken = Token(_levToken);
  }
  function version() external pure returns (string) {
    return "1.0.0";
  }
  function setLevToken(address _levToken) external validAddress(_levToken) onlyOwner {
    levToken = Token(_levToken);
  }
  function setFeeToken(address _feeToken) external validAddress(_feeToken) onlyOwner {
    feeToken = Fee(_feeToken);
  }
  function setWallet(address _wallet) external validAddress(_wallet) onlyOwner {
    wallet = _wallet;
  }
  function stakeTokens(uint _quantity) external isStaking notZero(_quantity) {
    require(levToken.allowance(msg.sender, this) >= _quantity);
    levBlocks[msg.sender] = levBlocks[msg.sender].add(_quantity.mul(endBlock.sub(block.number)));
    stakes[msg.sender] = stakes[msg.sender].add(_quantity);
    totalLevBlocks = totalLevBlocks.add(_quantity.mul(endBlock.sub(block.number)));
    totalLevs = totalLevs.add(_quantity);
    require(levToken.transferFrom(msg.sender, this, _quantity));
    StakeEvent(msg.sender, _quantity, startBlock, endBlock);
  }
  function revertFeeCalculatedFlag(bool _flag) external onlyOwner isDoneStaking {
    feeCalculated = _flag;
  }
  function updateFeeForCurrentStakingInterval() external onlyOperator isDoneStaking {
    require(feeCalculated == false);
    uint feeReceived = feeToken.balanceOf(this);
    feeForTheStakingInterval = feeForTheStakingInterval.add(feeReceived.add(this.balance.div(weiPerFee)));
    feeCalculated = true;
    FeeCalculated(feeForTheStakingInterval, feeReceived, this.balance, startBlock, endBlock);
    if (feeReceived > 0) feeToken.burnTokens(feeReceived);
    if (this.balance > 0) wallet.transfer(this.balance);
  }
  function redeemLevAndFeeByStaker() external {
    redeemLevAndFee(msg.sender);
  }
  function redeemLevAndFeeToStakers(address[] _stakers) external onlyOperator {
    for (uint i = 0; i < _stakers.length; i++) redeemLevAndFee(_stakers[i]);
  }
  function redeemLevAndFee(address _staker) private validAddress(_staker) isDoneStaking {
    require(feeCalculated);
    require(totalLevBlocks > 0);
    uint levBlock = levBlocks[_staker];
    uint stake = stakes[_staker];
    require(stake > 0);
    uint feeEarned = levBlock.mul(feeForTheStakingInterval).div(totalLevBlocks);
    delete stakes[_staker];
    delete levBlocks[_staker];
    totalLevs = totalLevs.sub(stake);
    if (feeEarned > 0) feeToken.sendTokens(_staker, feeEarned);
    require(levToken.transfer(_staker, stake));
    RedeemEvent(_staker, stake, feeEarned, startBlock, endBlock);
  }
  function startNewStakingInterval(uint _start, uint _end)
  external
  notZero(_start)
  notZero(_end)
  onlyOperator
  isDoneStaking
  {
    require(totalLevs == 0);
    startBlock = _start;
    endBlock = _end;
    totalLevBlocks = 0;
    feeForTheStakingInterval = 0;
    feeCalculated = false;
    StakingInterval(_start, _end);
  }
}