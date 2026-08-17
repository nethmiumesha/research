pragma solidity ^0.6.0;
import "../oracle/implementation/Finder.sol";
import "../oracle/implementation/Constants.sol";
import "../oracle/implementation/Voting.sol";
contract Umip3Upgrader {
    address public existingGovernor;
    Voting public existingVoting;
    address public newGovernor;
    Finder public finder;
    address public voting;
    address public identifierWhitelist;
    address public store;
    address public financialContractsAdmin;
    address public registry;
    constructor(
        address _existingGovernor,
        address _existingVoting,
        address _finder,
        address _voting,
        address _identifierWhitelist,
        address _store,
        address _financialContractsAdmin,
        address _registry,
        address _newGovernor
    ) public {
        existingGovernor = _existingGovernor;
        existingVoting = Voting(_existingVoting);
        finder = Finder(_finder);
        voting = _voting;
        identifierWhitelist = _identifierWhitelist;
        store = _store;
        financialContractsAdmin = _financialContractsAdmin;
        registry = _registry;
        newGovernor = _newGovernor;
    }
    function upgrade() external {
        require(msg.sender == existingGovernor, "Upgrade can only be initiated by the existing governor.");
        finder.changeImplementationAddress(OracleInterfaces.Oracle, voting);
        finder.changeImplementationAddress(OracleInterfaces.IdentifierWhitelist, identifierWhitelist);
        finder.changeImplementationAddress(OracleInterfaces.Store, store);
        finder.changeImplementationAddress(OracleInterfaces.FinancialContractsAdmin, financialContractsAdmin);
        finder.changeImplementationAddress(OracleInterfaces.Registry, registry);
        finder.transferOwnership(newGovernor);
        existingVoting.setMigrated(voting);
        existingVoting.transferOwnership(newGovernor);
    }
}