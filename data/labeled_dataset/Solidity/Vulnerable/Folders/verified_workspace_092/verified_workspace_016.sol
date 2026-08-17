pragma solidity ^0.8.4;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
contract OKLGFaaSToken is ERC20 {
  using SafeMath for uint256;
  bool public contractIsRemoved = false;
  IERC20 private _rewardsToken;
  IERC20 private _stakedERC20;
  IERC721 private _stakedERC721;
  PoolInfo public pool;
  address private constant _burner = 0x000000000000000000000000000000000000dEaD;
  struct PoolInfo {
    address creator;
    address tokenOwner;
    uint256 origTotSupply;
    uint256 curRewardsSupply;
    uint256 totalTokensStaked;
    uint256 creationBlock;
    uint256 perBlockNum;
    uint256 lockedUntilDate;
    uint256 lastRewardBlock;
    uint256 accERC20PerShare;
    uint256 stakeTimeLockSec;
    bool isStakedNft;
  }
  struct StakerInfo {
    uint256 amountStaked;
    uint256 blockOriginallyStaked;
    uint256 timeOriginallyStaked;
    uint256 blockLastHarvested;
    uint256 rewardDebt;
    uint256[] nftTokenIds;
  }
  struct BlockTokenTotal {
    uint256 blockNumber;
    uint256 totalTokens;
  }
  mapping(address => StakerInfo) public stakers;
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _rewardSupply,
    address _rewardsTokenAddy,
    address _stakedTokenAddy,
    address _originalTokenOwner,
    uint256 _perBlockAmount,
    uint256 _lockedUntilDate,
    uint256 _stakeTimeLockSec,
    bool _isStakedNft
  ) ERC20(_name, _symbol) {
    require(
      _perBlockAmount > uint256(0) && _perBlockAmount <= uint256(_rewardSupply),
      'per block amount must be more than 0 and less than supply'
    );
    require(
      _lockedUntilDate > block.timestamp || _lockedUntilDate == 0,
      'locked time must be after now or 0'
    );
    _rewardsToken = IERC20(_rewardsTokenAddy);
    if (_isStakedNft) {
      _stakedERC721 = IERC721(_stakedTokenAddy);
    } else {
      _stakedERC20 = IERC20(_stakedTokenAddy);
    }
    pool = PoolInfo({
      creator: msg.sender,
      tokenOwner: _originalTokenOwner,
      origTotSupply: _rewardSupply,
      curRewardsSupply: _rewardSupply,
      totalTokensStaked: 0,
      creationBlock: 0,
      perBlockNum: _perBlockAmount,
      lockedUntilDate: _lockedUntilDate,
      lastRewardBlock: block.number,
      accERC20PerShare: 0,
      stakeTimeLockSec: _stakeTimeLockSec,
      isStakedNft: _isStakedNft
    });
  }
  function updateSupply(uint256 _newSupply) external {
    require(
      msg.sender == pool.creator,
      'only contract creator can update the supply'
    );
    pool.origTotSupply = _newSupply;
    pool.curRewardsSupply = _newSupply;
  }
  function stakedTokenAddress() external view returns (address) {
    return pool.isStakedNft ? address(_stakedERC721) : address(_stakedERC20);
  }
  function rewardsTokenAddress() external view returns (address) {
    return address(_rewardsToken);
  }
  function tokenOwner() external view returns (address) {
    return pool.tokenOwner;
  }
  function getLockedUntilDate() external view returns (uint256) {
    return pool.lockedUntilDate;
  }
  function removeStakeableTokens() external {
    require(
      msg.sender == pool.creator || msg.sender == pool.tokenOwner,
      'caller must be the contract creator or owner to remove stakable tokens'
    );
    _rewardsToken.transfer(pool.tokenOwner, pool.curRewardsSupply);
    pool.curRewardsSupply = 0;
    contractIsRemoved = true;
  }
  function stakeTokens(uint256 _amount, uint256[] memory _tokenIds) public {
    require(
      getLastStakableBlock() > block.number,
      'this farm is expired and no more stakers can be added'
    );
    _updatePool();
    if (balanceOf(msg.sender) > 0) {
      _harvestTokens(msg.sender);
    }
    uint256 _finalAmountTransferred;
    if (pool.isStakedNft) {
      require(
        _tokenIds.length > 0,
        "you need to provide NFT token IDs you're staking"
      );
      for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
        _stakedERC721.transferFrom(msg.sender, address(this), _tokenIds[_i]);
      }
      _finalAmountTransferred = _tokenIds.length;
    } else {
      uint256 _contractBalanceBefore = _stakedERC20.balanceOf(address(this));
      _stakedERC20.transferFrom(msg.sender, address(this), _amount);
      _finalAmountTransferred = _stakedERC20.balanceOf(address(this)).sub(
        _contractBalanceBefore
      );
    }
    if (totalSupply() == 0) {
      pool.creationBlock = block.number;
      pool.lastRewardBlock = block.number;
    }
    _mint(msg.sender, _finalAmountTransferred);
    StakerInfo storage _staker = stakers[msg.sender];
    _staker.amountStaked = _staker.amountStaked.add(_finalAmountTransferred);
    _staker.blockOriginallyStaked = block.number;
    _staker.timeOriginallyStaked = block.timestamp;
    _staker.blockLastHarvested = block.number;
    _staker.rewardDebt = _staker.amountStaked.mul(pool.accERC20PerShare).div(
      1e36
    );
    for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
      _staker.nftTokenIds.push(_tokenIds[_i]);
    }
    _updNumStaked(_finalAmountTransferred, 'add');
    emit Deposit(msg.sender, _finalAmountTransferred);
  }
  function unstakeTokens(uint256 _amount, bool _shouldHarvest) external {
    StakerInfo memory _staker = stakers[msg.sender];
    uint256 _userBalance = _staker.amountStaked;
    require(
      pool.isStakedNft ? true : _amount <= _userBalance,
      'user can only unstake amount they have currently staked or less'
    );
    require(
      !_shouldHarvest ||
        block.timestamp >=
        _staker.timeOriginallyStaked.add(pool.stakeTimeLockSec) ||
        contractIsRemoved ||
        block.number > getLastStakableBlock(),
      'you have not staked for minimum time lock yet and the pool is not expired'
    );
    _updatePool();
    if (_shouldHarvest) {
      _harvestTokens(msg.sender);
    }
    uint256 _amountToRemoveFromStaked = pool.isStakedNft
      ? _userBalance
      : _amount;
    transfer(
      _burner,
      _amountToRemoveFromStaked > balanceOf(msg.sender)
        ? balanceOf(msg.sender)
        : _amountToRemoveFromStaked
    );
    if (pool.isStakedNft) {
      for (uint256 _i = 0; _i < _staker.nftTokenIds.length; _i++) {
        _stakedERC721.transferFrom(
          address(this),
          msg.sender,
          _staker.nftTokenIds[_i]
        );
      }
    } else {
      require(
        _stakedERC20.transfer(msg.sender, _amountToRemoveFromStaked),
        'unable to send user original tokens'
      );
    }
    if (balanceOf(msg.sender) <= 0) {
      delete stakers[msg.sender];
    } else {
      _staker.amountStaked = _staker.amountStaked.sub(
        _amountToRemoveFromStaked
      );
    }
    _updNumStaked(_amountToRemoveFromStaked, 'remove');
    emit Withdraw(msg.sender, _amountToRemoveFromStaked);
  }
  function emergencyUnstake() external {
    StakerInfo memory _staker = stakers[msg.sender];
    uint256 _amountToRemoveFromStaked = _staker.amountStaked;
    require(
      _amountToRemoveFromStaked > 0,
      'user can only unstake if they have tokens in the pool'
    );
    transfer(
      _burner,
      _amountToRemoveFromStaked > balanceOf(msg.sender)
        ? balanceOf(msg.sender)
        : _amountToRemoveFromStaked
    );
    if (pool.isStakedNft) {
      for (uint256 _i = 0; _i < _staker.nftTokenIds.length; _i++) {
        _stakedERC721.transferFrom(
          address(this),
          msg.sender,
          _staker.nftTokenIds[_i]
        );
      }
    } else {
      require(
        _stakedERC20.transfer(msg.sender, _amountToRemoveFromStaked),
        'unable to send user original tokens'
      );
    }
    delete stakers[msg.sender];
    _updNumStaked(_amountToRemoveFromStaked, 'remove');
    emit Withdraw(msg.sender, _amountToRemoveFromStaked);
  }
  function harvestForUser(address _userAddy, bool _autoCompound)
    external
    returns (uint256)
  {
    require(
      msg.sender == pool.creator || msg.sender == _userAddy,
      'can only harvest tokens for someone else if this was the contract creator'
    );
    _updatePool();
    uint256 _tokensToUser = _harvestTokens(_userAddy);
    if (
      _autoCompound &&
      !pool.isStakedNft &&
      address(_rewardsToken) == address(_stakedERC20)
    ) {
      uint256[] memory _placeholder;
      stakeTokens(_tokensToUser, _placeholder);
    }
    return _tokensToUser;
  }
  function getLastStakableBlock() public view returns (uint256) {
    uint256 _blockToAdd = pool.creationBlock == 0
      ? block.number
      : pool.creationBlock;
    return pool.origTotSupply.div(pool.perBlockNum).add(_blockToAdd);
  }
  function calcHarvestTot(address _userAddy) public view returns (uint256) {
    StakerInfo memory _staker = stakers[_userAddy];
    if (
      _staker.blockLastHarvested >= block.number ||
      _staker.blockOriginallyStaked == 0 ||
      pool.totalTokensStaked == 0
    ) {
      return uint256(0);
    }
    uint256 _accERC20PerShare = pool.accERC20PerShare;
    if (block.number > pool.lastRewardBlock && pool.totalTokensStaked != 0) {
      uint256 _endBlock = getLastStakableBlock();
      uint256 _lastBlock = block.number < _endBlock ? block.number : _endBlock;
      uint256 _nrOfBlocks = _lastBlock.sub(pool.lastRewardBlock);
      uint256 _erc20Reward = _nrOfBlocks.mul(pool.perBlockNum);
      _accERC20PerShare = _accERC20PerShare.add(
        _erc20Reward.mul(1e36).div(pool.totalTokensStaked)
      );
    }
    return
      _staker.amountStaked.mul(_accERC20PerShare).div(1e36).sub(
        _staker.rewardDebt
      );
  }
  function _updatePool() private {
    uint256 _endBlock = getLastStakableBlock();
    uint256 _lastBlock = block.number < _endBlock ? block.number : _endBlock;
    if (_lastBlock <= pool.lastRewardBlock) {
      return;
    }
    uint256 _stakedSupply = pool.totalTokensStaked;
    if (_stakedSupply == 0) {
      pool.lastRewardBlock = _lastBlock;
      return;
    }
    uint256 _nrOfBlocks = _lastBlock.sub(pool.lastRewardBlock);
    uint256 _erc20Reward = _nrOfBlocks.mul(pool.perBlockNum);
    pool.accERC20PerShare = pool.accERC20PerShare.add(
      _erc20Reward.mul(1e36).div(_stakedSupply)
    );
    pool.lastRewardBlock = _lastBlock;
  }
  function _harvestTokens(address _userAddy) private returns (uint256) {
    StakerInfo storage _staker = stakers[_userAddy];
    require(_staker.blockOriginallyStaked > 0, 'user must have tokens staked');
    uint256 _num2Trans = calcHarvestTot(_userAddy);
    if (_num2Trans > 0) {
      require(
        _rewardsToken.transfer(_userAddy, _num2Trans),
        'unable to send user their harvested tokens'
      );
      pool.curRewardsSupply = pool.curRewardsSupply.sub(_num2Trans);
    }
    _staker.rewardDebt = _staker.amountStaked.mul(pool.accERC20PerShare).div(
      1e36
    );
    _staker.blockLastHarvested = block.number;
    return _num2Trans;
  }
  function _updNumStaked(uint256 _amount, string memory _operation) private {
    if (_compareStr(_operation, 'remove')) {
      pool.totalTokensStaked = pool.totalTokensStaked.sub(_amount);
    } else {
      pool.totalTokensStaked = pool.totalTokensStaked.add(_amount);
    }
  }
  function _compareStr(string memory a, string memory b)
    private
    pure
    returns (bool)
  {
    return (keccak256(abi.encodePacked((a))) ==
      keccak256(abi.encodePacked((b))));
  }
}