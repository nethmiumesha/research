pragma solidity 0.7.5;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
interface IRewardEthToken is IERC20Upgradeable {
    event MaintainerUpdated(address maintainer);
    event MaintainerFeeUpdated(uint256 maintainerFee);
    struct Checkpoint {
        uint256 rewardPerToken;
        uint256 reward;
    }
    event RewardsUpdated(
        uint256 periodRewards,
        uint256 totalRewards,
        uint256 rewardPerToken,
        uint256 updateTimestamp
    );
    function initialize(
        address _admin,
        address _stakedEthToken,
        address _balanceReporters,
        address _stakedTokens,
        address _maintainer,
        uint256 _maintainerFee
    ) external;
    function maintainer() external view returns (address);
    function setMaintainer(address _newMaintainer) external;
    function maintainerFee() external view returns (uint256);
    function setMaintainerFee(uint256 _newMaintainerFee) external;
    function updateTimestamp() external view returns (uint256);
    function totalRewards() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function checkpoints(address account) external view returns (uint256, uint256);
    function updateRewardCheckpoint(address account) external;
    function updateTotalRewards(uint256 newTotalRewards) external;
    function claimRewards(address tokenContract, uint256 claimedRewards) external;
}