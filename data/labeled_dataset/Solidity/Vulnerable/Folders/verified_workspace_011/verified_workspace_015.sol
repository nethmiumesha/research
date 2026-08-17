pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IStakingRewardsFunctions {
    function notifyRewardAmount(uint256 reward) external;
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external;
    function setNewRewardsDistribution(address newRewardsDistribution) external;
}
interface IStakingRewards is IStakingRewardsFunctions {
    function rewardToken() external view returns (IERC20);
}