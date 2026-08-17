pragma solidity 0.4.25;
import { Ownable } from "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;
    uint256 public timeLockPeriod;
    mapping(bytes32 => uint256) public timeLockedUpgrades;
    event UpgradeRegistered(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );
    modifier timeLockUpgrade() {
        if (timeLockPeriod == 0) {
            _;
            return;
        }
        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );
        uint256 registrationTime = timeLockedUpgrades[upgradeHash];
        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;
            emit UpgradeRegistered(
                upgradeHash,
                block.timestamp
            );
            return;
        }
        require(
            block.timestamp >= registrationTime.add(timeLockPeriod),
            "TimeLockUpgrade.timeLockUpgrade: Upgrade requires time lock period to have elapsed."
        );
        timeLockedUpgrades[upgradeHash] = 0;
        _;
    }
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        external
        onlyOwner
    {
        if (timeLockPeriod == 0) {
            timeLockPeriod = _timeLockPeriod;
        }
    }
}