pragma solidity 0.7.5;
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../presets/OwnablePausableUpgradeable.sol";
import "../interfaces/IStakedEthToken.sol";
import "../interfaces/IRewardEthToken.sol";
import "./ERC20.sol";
contract StakedEthToken is IStakedEthToken, OwnablePausableUpgradeable, ERC20 {
    using SafeMathUpgradeable for uint256;
    uint256 public override totalDeposits;
    mapping(address => uint256) private deposits;
    address private pool;
    IRewardEthToken private rewardEthToken;
    function initialize(address _admin, address _rewardEthToken, address _pool) public override initializer {
        __OwnablePausableUpgradeable_init(_admin);
        __ERC20_init_unchained("StakeWise Staked ETH", "stETH");
        rewardEthToken = IRewardEthToken(_rewardEthToken);
        pool = _pool;
    }
    function totalSupply() public view override returns (uint256) {
        return totalDeposits;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return deposits[account];
    }
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        require(sender != address(0), "StakedEthToken: transfer from the zero address");
        require(recipient != address(0), "StakedEthToken: transfer to the zero address");
        rewardEthToken.updateRewardCheckpoint(sender);
        deposits[sender] = deposits[sender].sub(amount, "StakedEthToken: invalid amount");
        rewardEthToken.updateRewardCheckpoint(recipient);
        deposits[recipient] = deposits[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function mint(address account, uint256 amount) external override {
        require(msg.sender == pool, "StakedEthToken: permission denied");
        rewardEthToken.updateRewardCheckpoint(account);
        totalDeposits = totalDeposits.add(amount);
        deposits[account] = deposits[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}