pragma solidity ^0.8.28;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
contract SthUSDRewards is AccessControl {
    bytes32 public constant BPS_SETTER_ROLE = keccak256("BPS_SETTER_ROLE");
    uint256 public rewardsBps;
    event RewardsBpsUpdated(uint256 oldBps, uint256 newBps);
    constructor(address _owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }
    function setRewardsBps(uint256 _rewardsBps) external onlyRole(BPS_SETTER_ROLE) {
        uint256 oldBps = rewardsBps;
        rewardsBps = _rewardsBps;
        emit RewardsBpsUpdated(oldBps, _rewardsBps);
    }
}