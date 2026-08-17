pragma solidity ^0.8.0;
import "./IRegistry.sol";
import "./SafeGuard.sol";
import "./mocks/Timelock.sol";
contract SafeGuardFactory {
    address public registry;
    uint8 public constant SAFE_GUARD_VERSION = 1;
    event SafeGuardCreated(
        address indexed admin,
        address indexed safeGuardAddress,
        address indexed timelockAddress,
        string safeName
    );
    constructor(address registry_) {
        registry = registry_;
    }
    function createSafeGuard(uint delay_, string memory safeGuardName, address admin, bytes32[] memory roles, address[] memory rolesAssignees) external returns (address) {
        require(roles.length == rolesAssignees.length, "SafeGuardFactory::create: roles assignment arity mismatch");
        SafeGuard safeGuard = new SafeGuard(admin, roles, rolesAssignees);
        Timelock timelock = new Timelock(address(safeGuard), delay_);
        safeGuard.setTimelock(address(timelock));
        IRegistry(registry).register(address(safeGuard), SAFE_GUARD_VERSION);
        emit SafeGuardCreated(admin, address(safeGuard), address(timelock), safeGuardName);
        return address(safeGuard);
    }
}