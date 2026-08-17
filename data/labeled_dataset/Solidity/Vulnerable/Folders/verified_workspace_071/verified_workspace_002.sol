pragma solidity ^0.5.16;
import "./RErc20.sol";
contract RErc20Delegate is RErc20, RDelegateInterface {
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