pragma solidity 0.8.9;
import "./Whitelist.sol";
import "./WhitelistRolesWithManager.sol";
import "./interfaces/IWhitelistWithManager.sol";
contract WhitelistWithManager is
    Whitelist,
    WhitelistRolesWithManager,
    IWhitelistWithManager
{
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    )
        WhitelistRolesWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
    {}
    function extendWhitelistExpiration(
        bytes32 serviceId,
        address user,
        uint64 expirationTimestamp
    ) external override {
        require(
            hasWhitelistExpirationExtenderRoleOrIsManager(msg.sender),
            "Cannot extend expiration"
        );
        require(serviceId != bytes32(0), "Service ID zero");
        require(user != address(0), "User address zero");
        _extendWhitelistExpiration(serviceId, user, expirationTimestamp);
        emit ExtendedWhitelistExpiration(
            serviceId,
            user,
            msg.sender,
            expirationTimestamp
        );
    }
    function setWhitelistExpiration(
        bytes32 serviceId,
        address user,
        uint64 expirationTimestamp
    ) external override {
        require(
            hasWhitelistExpirationSetterRoleOrIsManager(msg.sender),
            "Cannot set expiration"
        );
        require(serviceId != bytes32(0), "Service ID zero");
        require(user != address(0), "User address zero");
        _setWhitelistExpiration(serviceId, user, expirationTimestamp);
        emit SetWhitelistExpiration(
            serviceId,
            user,
            msg.sender,
            expirationTimestamp
        );
    }
    function setIndefiniteWhitelistStatus(
        bytes32 serviceId,
        address user,
        bool status
    ) external override {
        require(
            hasIndefiniteWhitelisterRoleOrIsManager(msg.sender),
            "Cannot set indefinite status"
        );
        require(serviceId != bytes32(0), "Service ID zero");
        require(user != address(0), "User address zero");
        uint192 indefiniteWhitelistCount = _setIndefiniteWhitelistStatus(
            serviceId,
            user,
            status
        );
        emit SetIndefiniteWhitelistStatus(
            serviceId,
            user,
            msg.sender,
            status,
            indefiniteWhitelistCount
        );
    }
    function revokeIndefiniteWhitelistStatus(
        bytes32 serviceId,
        address user,
        address setter
    ) external override {
        require(
            !hasIndefiniteWhitelisterRoleOrIsManager(setter),
            "setter can set indefinite status"
        );
        (
            bool revoked,
            uint192 indefiniteWhitelistCount
        ) = _revokeIndefiniteWhitelistStatus(serviceId, user, setter);
        if (revoked) {
            emit RevokedIndefiniteWhitelistStatus(
                serviceId,
                user,
                setter,
                msg.sender,
                indefiniteWhitelistCount
            );
        }
    }
}