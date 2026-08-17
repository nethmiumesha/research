pragma solidity 0.7.5;
interface IStakedTokens {
    struct Token {
        bool enabled;
        uint256 totalSupply;
        uint256 totalRewards;
        uint256 rewardRate;
    }
    event TokensStaked(address indexed token, address indexed account, uint256 amount);
    event TokenToggled(address indexed token, bool isEnabled);
    event RewardWithdrawn(address indexed token, address account, uint256 amount);
    event TokensWithdrawn(address indexed token, address indexed account, uint256 amount);
    function tokens(address _token) external view returns (bool, uint256, uint256, uint256);
    function initialize(address _admin, address _rewardEthToken) external;
    function toggleTokenContract(address _token, bool _isSupported) external;
    function stakeTokens(address _token, uint256 _amount) external;
    function withdrawTokens(address _token, uint256 _amount) external;
    function withdrawRewards(address _token) external;
    function balanceOf(address _token, address _account) external view returns (uint256);
    function rewardRateOf(address _token, address _account) external view returns (uint256);
    function rewardOf(address _token, address _account) external view returns (uint256);
}