pragma solidity 0.8.9;
interface IWhitelistRoles {
    function WHITELIST_EXPIRATION_EXTENDER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);
    function WHITELIST_EXPIRATION_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);
    function INDEFINITE_WHITELISTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);
}