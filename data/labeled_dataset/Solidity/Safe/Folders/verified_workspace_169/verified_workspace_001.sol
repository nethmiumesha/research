pragma solidity ^0.6.0;
import "../oracle/implementation/Finder.sol";
import "../oracle/implementation/Constants.sol";
import "../oracle/implementation/Voting.sol";
contract Umip15Upgrader {
    address public governor;
    Voting public existingVoting;
    Finder public finder;
    address public newVoting;
    constructor(
        address _governor,
        address _existingVoting,
        address _newVoting,
        address _finder
    ) public {
        governor = _governor;
        existingVoting = Voting(_existingVoting);
        newVoting = _newVoting;
        finder = Finder(_finder);
    }
    function upgrade() external {
        require(msg.sender == governor, "Upgrade can only be initiated by the existing governor.");
        finder.changeImplementationAddress(OracleInterfaces.Oracle, newVoting);
        existingVoting.setMigrated(newVoting);
        existingVoting.transferOwnership(governor);
        finder.transferOwnership(governor);
    }
}