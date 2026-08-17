pragma solidity 0.6.6;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
abstract contract IWexMaster {
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 pendingRewards;
  }
  struct PoolInfo {
    IERC20 lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accWexPerShare;
  }
  address public wex;
  mapping(uint256 => PoolInfo) public poolInfo;
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _withdrawRewards
  ) external virtual;
  function withdraw(
    uint256 _pid,
    uint256 _amount,
    bool _withdrawRewards
  ) external virtual;
  function pendingWex(uint256 _pid, address _user) external virtual returns (uint256);
}