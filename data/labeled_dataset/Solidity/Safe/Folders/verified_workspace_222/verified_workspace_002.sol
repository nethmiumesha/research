pragma solidity 0.7.5;
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../presets/OwnablePausableUpgradeable.sol";
import "../interfaces/IStakedEthToken.sol";
import "../interfaces/IRewardEthToken.sol";
import "./ERC20.sol";
contract RewardEthToken is IRewardEthToken, OwnablePausableUpgradeable, ERC20 {
    using SafeMathUpgradeable for uint256;
    uint256 public override updateTimestamp;
    uint256 public override totalRewards;
    mapping(address => Checkpoint) public override checkpoints;
    uint256 public override rewardPerToken;
    uint256 public override maintainerFee;
    address public override maintainer;
    IStakedEthToken private stakedEthToken;
    address private balanceReporters;
    address private stakedTokens;
    function initialize(
        address _admin,
        address _stakedEthToken,
        address _balanceReporters,
        address _stakedTokens,
        address _maintainer,
        uint256 _maintainerFee
    )
        public override initializer
    {
        __OwnablePausableUpgradeable_init(_admin);
        __ERC20_init_unchained("StakeWise Reward ETH", "rwETH");
        stakedEthToken = IStakedEthToken(_stakedEthToken);
        balanceReporters = _balanceReporters;
        stakedTokens = _stakedTokens;
        maintainer = _maintainer;
        emit MaintainerUpdated(_maintainer);
        maintainerFee = _maintainerFee;
        emit MaintainerFeeUpdated(_maintainerFee);
    }
    function setMaintainer(address _newMaintainer) external override onlyAdmin {
        maintainer = _newMaintainer;
        emit MaintainerUpdated(_newMaintainer);
    }
    function setMaintainerFee(uint256 _newMaintainerFee) external override onlyAdmin {
        require(_newMaintainerFee < 10000, "RewardEthToken: invalid new maintainer fee");
        maintainerFee = _newMaintainerFee;
        emit MaintainerFeeUpdated(_newMaintainerFee);
    }
    function totalSupply() external view override returns (uint256) {
        return totalRewards;
    }
    function balanceOf(address account) public view override returns (uint256) {
        Checkpoint memory cp = checkpoints[account];
        uint256 periodRewardPerToken = rewardPerToken.sub(cp.rewardPerToken);
        if (periodRewardPerToken == 0) {
            return cp.reward;
        }
        uint256 deposit = stakedEthToken.balanceOf(account);
        if (deposit == 0) {
            return cp.reward;
        }
        return cp.reward.add(deposit.mul(periodRewardPerToken).div(1e18));
    }
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        require(sender != address(0), "RewardEthToken: transfer from the zero address");
        require(recipient != address(0), "RewardEthToken: transfer to the zero address");
        checkpoints[sender] = Checkpoint(rewardPerToken, balanceOf(sender).sub(amount, "RewardEthToken: invalid amount"));
        checkpoints[recipient] = Checkpoint(rewardPerToken, balanceOf(recipient).add(amount));
        emit Transfer(sender, recipient, amount);
    }
    function updateRewardCheckpoint(address account) external override {
        checkpoints[account] = Checkpoint(rewardPerToken, balanceOf(account));
    }
    function updateTotalRewards(uint256 newTotalRewards) external override {
        require(msg.sender == balanceReporters, "RewardEthToken: permission denied");
        uint256 periodRewards = newTotalRewards.sub(totalRewards, "RewardEthToken: invalid new total rewards");
        if (periodRewards == 0) {
            return;
        }
        uint256 maintainerReward = periodRewards.mul(maintainerFee).div(10000);
        rewardPerToken = rewardPerToken.add(periodRewards.sub(maintainerReward).mul(1e18).div(stakedEthToken.totalDeposits()));
        checkpoints[maintainer] = Checkpoint(
            rewardPerToken,
            balanceOf(maintainer).add(maintainerReward)
        );
        updateTimestamp = block.timestamp;
        totalRewards = newTotalRewards;
        emit RewardsUpdated(periodRewards, newTotalRewards, rewardPerToken, updateTimestamp);
    }
    function claimRewards(address tokenContract, uint256 claimedRewards) external override {
        require(msg.sender == stakedTokens, "RewardEthToken: permission denied");
        _transfer(tokenContract, stakedTokens, claimedRewards);
    }
}