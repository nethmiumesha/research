pragma solidity ^0.5.16;
import "./VBep20.sol";
contract VBep20Delegate is VBep20, VDelegateInterface {
    constructor() public {}
    function _becomeImplementation(bytes memory data) public {
        data;
        if (false) {
            implementation = address(0);
        }
        require(msg.sender == admin, "only the admin may call _becomeImplementation");
    }
    function _resignImplementation() public {
        if (false) {
            implementation = address(0);
        }
        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}