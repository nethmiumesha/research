pragma solidity ^0.5.0;
contract ProxyAdmin {
    function admin() external returns (address);
    function upgradeTo(address _newImplementation) external;
    function changeAdmin(address _newAdmin) external;
}