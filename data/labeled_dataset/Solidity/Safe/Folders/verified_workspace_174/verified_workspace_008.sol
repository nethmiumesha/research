pragma solidity ^0.8.0;
import 'https:
import 'https:
import 'https:
pragma solidity ^0.8.0;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}
interface CssReferral {
    function setCssReferral(address farmer, address referrer) external;
    function getCssReferral(address farmer) external view returns (address);
}
contract Staking is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 depositTime;
    }
    struct PoolInfo {
        IBEP20 stakeToken;
        uint256 lastRewardBlock;
        uint256 accRewardTokenPerShare;
    }
    IBEP20 public immutable stakeToken;
    IBEP20 public immutable rewardToken;
    uint256 public immutable rewardPerBlock;
    PoolInfo public poolInfo;
    mapping (address => UserInfo) public userInfo;
    uint256 public immutable startBlock;
    uint256 public immutable endBlock;
    address public divPoolAddress;
    uint256 public constant DIV_REFERRAL_FEE = 1500;
    uint256 public immutable divPoolFee;
    uint256 public threshold = 1000*1e18;
    address public rewardReferral;
    address public airdropContract;
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardWithdraw(address indexed user, uint256 amount);
    event StopReward(address indexed user, uint256 _endBlock);
    event RewardPaid(address indexed user, uint256 reward);
    event ReferralPaid(address indexed user, address indexed userTo, uint256 reward);
    event SetRewardReferralAddress(address indexed sender, address indexed referralAddress);
    event SetDevPoolAddress(address indexed sender, address indexed divPoolAddress);
    constructor(
        IBEP20 _stakeToken,
        IBEP20 _rewardToken,
        address _divPoolAddress,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _divPoolFee
    ) {
        require(_divPoolFee <= 500, 'Total fee cannot be higher than 5%');
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        divPoolAddress = _divPoolAddress;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        divPoolFee = _divPoolFee;
        poolInfo = PoolInfo({
            stakeToken: _stakeToken,
            lastRewardBlock: _startBlock,
            accRewardTokenPerShare: 0
        });
    }
    function setThreshold(uint _threshold) external onlyOwner{
        threshold = _threshold;
    }
    function getMultiplierForBlocks(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokenPerShare = pool.accRewardTokenPerShare;
        uint256 stakeTokenSupply = pool.stakeToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && stakeTokenSupply != 0) {
            uint256 multiplier = getMultiplierForBlocks(pool.lastRewardBlock, block.number);
            uint256 rewardTokenReward = multiplier.mul(rewardPerBlock);
            accRewardTokenPerShare = accRewardTokenPerShare.add(rewardTokenReward.mul(1e12).div(stakeTokenSupply));
        }
        return user.amount.mul(accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
    }
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stakeTokenSupply = pool.stakeToken.balanceOf(address(this));
        if (stakeTokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplierForBlocks(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward = multiplier.mul(rewardPerBlock);
        pool.accRewardTokenPerShare = pool.accRewardTokenPerShare.add(rewardTokenReward.mul(1e12).div(stakeTokenSupply));
        pool.lastRewardBlock = block.number;
    }
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require((block.number >= pool.lastRewardBlock || _amount == 0), "pool didnt start yet");
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
                emit RewardPaid(msg.sender, pending);
            }
        }else{
            if(_amount>threshold)
                user.depositTime = block.timestamp;
        }
        if(_amount > 0) {
            pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 treasuryFee = _amount.mul(divPoolFee).div(10000);
            pool.stakeToken.safeTransfer(divPoolAddress, treasuryFee);
            user.amount = user.amount.add(_amount).sub(treasuryFee);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }
    function withdraw(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            payRefFees(pending);
            rewardToken.safeTransfer(address(msg.sender), pending);
            emit RewardPaid(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardTokenPerShare).div(1e12);
        if(user.amount<threshold)
            user.depositTime = 0;
        emit Withdraw(msg.sender, _amount);
    }
    function payRefFees(uint256 pending) internal
    {
        uint256 toReferral = pending.mul(DIV_REFERRAL_FEE).div(10000);
        address referrer = address(0);
        if (rewardReferral != address(0)) {
            referrer = CssReferral(rewardReferral).getCssReferral(msg.sender);
        }
        if (referrer != address(0)) {
            rewardToken.safeTransfer(referrer, toReferral);
            emit ReferralPaid(msg.sender, referrer, toReferral);
        }
    }
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        pool.stakeToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
    function rewardWithdraw() public onlyOwner {
        require(endBlock <= block.number + 288000, "It too early to withdraw reward tokens");
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(divPoolAddress, balance);
        emit RewardWithdraw(msg.sender, balance);
    }
    function setRewardReferral(address _rewardReferral) external onlyOwner {
        rewardReferral = _rewardReferral;
        emit SetRewardReferralAddress(msg.sender, _rewardReferral);
    }
    function setDivPoolAddress(address _divPoolAddress) public onlyOwner {
        divPoolAddress = _divPoolAddress;
        emit SetDevPoolAddress(msg.sender, _divPoolAddress);
    }
    function getUserInfo(address user) public returns(UserInfo memory result){
        UserInfo memory result = userInfo[user];
        return result;
    }
    function clearUserDepositTime(address user) public {
        require(msg.sender==airdropContract,"can't clear");
        UserInfo memory result = userInfo[user];
        result.depositTime = 0;
    }
    function setAirDropContract(address _airdrop) onlyOwner public{
        airdropContract = _airdrop;
    }
}