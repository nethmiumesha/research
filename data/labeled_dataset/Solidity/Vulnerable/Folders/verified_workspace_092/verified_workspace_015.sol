pragma solidity ^0.8.4;
import './OKLGFaaSToken.sol';
import './OKLGProduct.sol';
contract OKLGFaaS is OKLGProduct {
  mapping(address => address[]) public tokensUpForStaking;
  address[] public allFarmingContracts;
  uint256 public totalStakingContracts;
  constructor(address _tokenAddress, address _spendAddress)
    OKLGProduct(uint8(8), _tokenAddress, _spendAddress)
  {}
  function getAllFarmingContracts() external view returns (address[] memory) {
    return allFarmingContracts;
  }
  function getTokensForStaking(address _tokenAddress)
    external
    view
    returns (address[] memory)
  {
    return tokensUpForStaking[_tokenAddress];
  }
  function createNewTokenContract(
    address _rewardsTokenAddy,
    address _stakedTokenAddy,
    uint256 _supply,
    uint256 _perBlockAllocation,
    uint256 _lockedUntilDate,
    uint256 _timelockSeconds,
    bool _isStakedNft
  ) external payable {
    _payForService(0);
    ERC20 _rewToken = ERC20(_rewardsTokenAddy);
    _rewToken.transferFrom(msg.sender, address(this), _supply);
    uint256 _updatedSupply = _supply <= _rewToken.balanceOf(address(this))
      ? _supply
      : _rewToken.balanceOf(address(this));
    OKLGFaaSToken _contract = new OKLGFaaSToken(
      'OKLG Staking Token',
      'sOKLG',
      _updatedSupply,
      _rewardsTokenAddy,
      _stakedTokenAddy,
      msg.sender,
      _perBlockAllocation,
      _lockedUntilDate,
      _timelockSeconds,
      _isStakedNft
    );
    allFarmingContracts.push(address(_contract));
    tokensUpForStaking[_stakedTokenAddy].push(address(_contract));
    totalStakingContracts++;
    _rewToken.transfer(address(_contract), _updatedSupply);
    uint256 _finalSupply = _updatedSupply <=
      _rewToken.balanceOf(address(_contract))
      ? _updatedSupply
      : _rewToken.balanceOf(address(_contract));
    if (_updatedSupply != _finalSupply) {
      _contract.updateSupply(_finalSupply);
    }
  }
  function removeTokenContract(address _faasTokenAddy) external {
    OKLGFaaSToken _contract = OKLGFaaSToken(_faasTokenAddy);
    require(
      msg.sender == _contract.tokenOwner(),
      'user must be the original token owner to remove tokens'
    );
    require(
      block.timestamp > _contract.getLockedUntilDate() &&
        _contract.getLockedUntilDate() != 0,
      'it must be after the locked time the user originally configured and not locked forever'
    );
    _contract.removeStakeableTokens();
    totalStakingContracts--;
  }
}