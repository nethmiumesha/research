pragma solidity >=0.6.11;
import "./Owned.sol";
abstract contract RewardsDistributionRecipient is Owned {
    address public rewardsDistribution;
    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}