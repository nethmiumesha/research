pragma solidity ^0.5.0;
import "../access/roles/PauserRole.sol";
contract PauserRoleMock is PauserRole {
    function removePauser(address account) public {
        _removePauser(account);
    }
    function onlyPauserMock() public view onlyPauser {
    }
    function _removePauser(address account) internal {
        super._removePauser(account);
    }
}