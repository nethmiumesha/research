pragma solidity 0.7.5;
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../presets/OwnablePausableUpgradeable.sol";
import "../interfaces/IRewardEthToken.sol";
import "../interfaces/IStakedTokens.sol";
contract StakedTokens is IStakedTokens, OwnablePausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    mapping(address => Token) public override tokens;
    mapping(address => mapping(address => uint256)) private rewardRates;
    mapping(address => mapping(address => uint256)) private balances;
    address private rewardEthToken;
    function initialize(address _admin, address _rewardEthToken) public override initializer {
        __OwnablePausableUpgradeable_init(_admin);
        __ReentrancyGuard_init_unchained();
        rewardEthToken = _rewardEthToken;
    }
    function toggleTokenContract(address _token, bool _isEnabled) external override onlyAdmin {
        require(_token != address(0), "StakedTokens: invalid token address");
        Token storage token = tokens[_token];
        token.enabled = _isEnabled;
        updateTokenRewards(_token);
        emit TokenToggled(_token, _isEnabled);
    }
    function stakeTokens(address _token, uint256 _amount) external override nonReentrant whenNotPaused {
        Token storage token = tokens[_token];
        require(token.enabled, "StakedTokens: token is not supported");
        updateTokenRewards(_token);
        _withdrawRewards(_token, msg.sender);
        token.totalSupply = token.totalSupply.add(_amount);
        balances[_token][msg.sender] = balances[_token][msg.sender].add(_amount);
        emit TokensStaked(_token, msg.sender, _amount);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }
    function withdrawTokens(address _token, uint256 _amount) external override nonReentrant whenNotPaused {
        updateTokenRewards(_token);
        _withdrawRewards(_token, msg.sender);
        Token storage token = tokens[_token];
        token.totalSupply = token.totalSupply.sub(_amount, "StakedTokens: invalid tokens amount");
        balances[_token][msg.sender] = balances[_token][msg.sender].sub(_amount, "StakedTokens: invalid tokens amount");
        emit TokensWithdrawn(_token, msg.sender, _amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    function withdrawRewards(address _token) external override nonReentrant whenNotPaused {
        updateTokenRewards(_token);
        _withdrawRewards(_token, msg.sender);
    }
    function balanceOf(address _token, address _account) external view override returns (uint256) {
        return balances[_token][_account];
    }
    function rewardRateOf(address _token, address _account) external view override returns (uint256) {
        return rewardRates[_token][_account];
    }
    function rewardOf(address _token, address _account) external override view returns (uint256) {
        Token memory token = tokens[_token];
        if (token.totalSupply == 0) {
            return 0;
        }
        uint256 tokenPeriodReward = IERC20(rewardEthToken).balanceOf(_token);
        uint256 accountRewardRate = rewardRates[_token][_account];
        uint256 accountBalance = balances[_token][_account];
        if (tokenPeriodReward == 0) {
            return accountBalance.mul(token.rewardRate.sub(accountRewardRate)).div(1e18);
        }
        uint256 rewardRate = token.rewardRate.add(tokenPeriodReward.mul(1e18).div(token.totalSupply));
        return accountBalance.mul(rewardRate.sub(accountRewardRate)).div(1e18);
    }
    function updateTokenRewards(address _token) private {
        Token storage token = tokens[_token];
        uint256 claimedRewards = IRewardEthToken(rewardEthToken).balanceOf(_token);
        if (token.totalSupply == 0 || claimedRewards == 0) {
            return;
        }
        token.rewardRate = token.rewardRate.add(claimedRewards.mul(1e18).div(token.totalSupply));
        token.totalRewards = token.totalRewards.add(claimedRewards);
        IRewardEthToken(rewardEthToken).claimRewards(_token, claimedRewards);
    }
    function _withdrawRewards(address _token, address _account) private {
        Token storage token = tokens[_token];
        uint256 accountRewardRate = rewardRates[_token][_account];
        if (token.rewardRate == accountRewardRate) {
            return;
        }
        rewardRates[_token][_account] = token.rewardRate;
        uint256 accountBalance = balances[_token][_account];
        if (accountBalance == 0) {
            return;
        }
        uint256 periodReward = accountBalance.mul(token.rewardRate.sub(accountRewardRate)).div(1e18);
        token.totalRewards = token.totalRewards.sub(periodReward);
        emit RewardWithdrawn(_token, _account, periodReward);
        IERC20(rewardEthToken).safeTransfer(_account, periodReward);
    }
}