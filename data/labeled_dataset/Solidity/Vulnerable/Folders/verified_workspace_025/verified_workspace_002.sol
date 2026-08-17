pragma solidity ^0.8.0;
import "./AccessControl.sol";
import "./EnumerableSet.sol";
abstract contract AccessControlEnumerable is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roleMembers[role].at(index);
    }
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roleMembers[role].length();
    }
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}