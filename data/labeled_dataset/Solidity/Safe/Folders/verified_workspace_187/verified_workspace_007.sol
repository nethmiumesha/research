pragma solidity >=0.6.10 <0.8.0;
abstract contract ProxyUtility {
    bytes32 private constant _ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    modifier onlyProxyAdmin() {
        bytes32 slot = _ADMIN_SLOT;
        address proxyAdmin;
        assembly {
            proxyAdmin := sload(slot)
        }
        require(msg.sender == proxyAdmin, "Only proxy admin");
        _;
    }
}