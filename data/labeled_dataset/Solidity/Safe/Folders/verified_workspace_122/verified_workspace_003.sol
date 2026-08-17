pragma solidity 0.8.5;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BLSToken.sol";
contract BlocksStaking is Ownable {
    using SafeERC20 for BLSToken;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 takeoverReward;
    }
    uint256 constant BURN_PERCENT_WITHDRAWAL = 1;
    uint256 public rewardsDistributionPeriod = 24 days / 3;
    uint256 public totalTokens;
    uint256 public rewardsPerBlock;
    uint256 public rewardsFinishedBlock;
    uint256 public accRewardsPerShare;
    uint256 public lastRewardCalculatedBlock;
    uint256 public allUsersRewardDebt;
    uint256 public takeoverRewards;
    mapping(address => UserInfo) public userInfo;
    BLSToken private blsToken;
    event Claim(address indexed user, uint256 reward);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event RewardDistributionPeriodSet(uint256 period);
    constructor(BLSToken blsTokenAddress_) {
        blsToken = BLSToken(blsTokenAddress_);
    }
    function setRewardDistributionPeriod(uint256 period_) external onlyOwner {
        rewardsDistributionPeriod = period_;
        emit RewardDistributionPeriodSet(period_);
    }
    function pendingRewards(address user_) public view returns (uint256) {
        UserInfo storage user = userInfo[user_];
        uint256 tempAccRewardsPerShare = accRewardsPerShare;
        if (user.amount > 0) {
            tempAccRewardsPerShare = tempAccRewardsPerShare + (rewardsPerBlock * getMultiplier()) / totalTokens;
        }
        return ((tempAccRewardsPerShare * user.amount) / 1e12) + user.takeoverReward - user.rewardDebt;
    }
    function rewardsPerBlockPerToken() external view returns(uint256) {
        if (block.number > rewardsFinishedBlock || totalTokens <= 0) {
            return 0;
        } else {
            return rewardsPerBlock / totalTokens;
        }
    }
    function getMultiplier() internal view returns (uint256) {
        if (block.number > rewardsFinishedBlock) {
            if(rewardsFinishedBlock >= lastRewardCalculatedBlock){
                return rewardsFinishedBlock - lastRewardCalculatedBlock;
            }else{
                return 0;
            }
        }else{
            return block.number - lastRewardCalculatedBlock;
        }
    }
    function updateState() internal {
        if(totalTokens > 0){
            accRewardsPerShare = accRewardsPerShare + (rewardsPerBlock * getMultiplier()) / totalTokens;
        }
        lastRewardCalculatedBlock = block.number;
    }
    function deposit(uint256 amount_) external {
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            claim();
        }
        if (totalTokens > 0) {
            updateState();
        } else {
            calculateRewardsDistribution();
            lastRewardCalculatedBlock = block.number;
        }
        totalTokens = totalTokens + amount_;
        uint256 userRewardDebtBefore = user.rewardDebt;
        user.amount = user.amount + amount_;
        user.rewardDebt = (accRewardsPerShare * user.amount) / 1e12;
        allUsersRewardDebt = allUsersRewardDebt + user.rewardDebt - userRewardDebtBefore;
        emit Deposit(msg.sender, amount_);
        blsToken.safeTransferFrom(address(msg.sender), address(this), amount_);
    }
    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, "No amount deposited for withdrawal.");
        claim();
        totalTokens = totalTokens - amount;
        if(totalTokens == 0 && rewardsFinishedBlock > block.number){
            allUsersRewardDebt = 0;
        }else{
            allUsersRewardDebt = allUsersRewardDebt - user.rewardDebt;
        }
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 burnAmount = amount * BURN_PERCENT_WITHDRAWAL / 100;
        blsToken.burn(burnAmount);
        uint256 amountWithdrawn = safeBlsTransfer(address(msg.sender), amount - burnAmount);
        emit Withdraw(msg.sender, amountWithdrawn);
    }
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        totalTokens = totalTokens - amount;
        allUsersRewardDebt = allUsersRewardDebt - user.rewardDebt;
        user.amount = 0;
        user.rewardDebt = 0;
        user.takeoverReward = 0;
        uint256 burnAmount = amount * BURN_PERCENT_WITHDRAWAL / 100;
        blsToken.burn(burnAmount);
        uint256 amountWithdrawn = safeBlsTransfer(address(msg.sender), amount - burnAmount);
        emit EmergencyWithdraw(msg.sender, amountWithdrawn);
    }
    function claim() public {
        updateState();
        uint256 reward = pendingRewards(msg.sender);
        if (reward <= 0) return;
        UserInfo storage user = userInfo[msg.sender];
        takeoverRewards = takeoverRewards - user.takeoverReward;
        user.rewardDebt = (accRewardsPerShare * user.amount) / 1e12;
        allUsersRewardDebt = allUsersRewardDebt + reward - user.takeoverReward;
        user.takeoverReward = 0;
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed.");
        emit Claim(msg.sender, reward);
    }
    function distributeRewards(address[] calldata addresses_, uint256[] calldata rewards_) external payable {
        uint256 tmpTakeoverRewards;
        for (uint256 i = 0; i < addresses_.length; ++i) {
            userInfo[addresses_[i]].takeoverReward = userInfo[addresses_[i]].takeoverReward + rewards_[i];
            tmpTakeoverRewards = tmpTakeoverRewards + rewards_[i];
        }
        takeoverRewards = takeoverRewards + tmpTakeoverRewards;
        if (msg.value - tmpTakeoverRewards > 0 && totalTokens > 0) {
            updateState();
            calculateRewardsDistribution();
        }
    }
    function calculateRewardsDistribution() internal {
        uint256 allReservedRewards = (accRewardsPerShare * totalTokens) / 1e12;
        uint256 availableForDistribution = (address(this).balance + allUsersRewardDebt - allReservedRewards - takeoverRewards);
        rewardsPerBlock = (availableForDistribution * 1e12) / rewardsDistributionPeriod;
        rewardsFinishedBlock = block.number + rewardsDistributionPeriod;
    }
    function safeBlsTransfer(address to_, uint256 amount_) internal returns (uint256) {
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (amount_ > blsBalance) {
            blsToken.transfer(to_, blsBalance);
            return blsBalance;
        } else {
            blsToken.transfer(to_, amount_);
            return amount_;
        }
    }
}