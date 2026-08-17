pragma solidity 0.8.10;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
contract IPancakeMasterChef {
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }
  struct PoolInfo {
    ERC20Upgradeable lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accCakePerShare;
  }
  address public cake;
  mapping(uint256 => PoolInfo) public poolInfo;
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  function deposit(uint256 _pid, uint256 _amount) external {}
  function withdraw(uint256 _pid, uint256 _amount) external {}
  function pendingCake(uint256 _pid, address _user) external view returns (uint256) {}
  function enterStaking(uint256 _amount) public {}
  function leaveStaking(uint256 _amount) public {}
}