pragma solidity 0.7.6;
interface RocketDAOProtocolSettingsRewardsInterface {
    function setSettingRewardsClaimer(string memory _contractName, uint256 _perc) external;
    function getRewardsClaimerPerc(string memory _contractName) external view returns (uint256);
    function getRewardsClaimerPercBlockUpdated(string memory _contractName) external view returns (uint256);
    function getRewardsClaimersPercTotal() external view returns (uint256);
    function getRewardsClaimIntervalBlocks() external view returns (uint256);
}