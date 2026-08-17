pragma solidity ^0.8.7;
contract PausableMapUpgradeable {
    event Paused(bytes32 name);
    event Unpaused(bytes32 name);
    mapping(bytes32 => bool) public paused;
    function _pause(bytes32 name) internal {
        require(!paused[name], "18");
        paused[name] = true;
        emit Paused(name);
    }
    function _unpause(bytes32 name) internal {
        require(paused[name], "19");
        paused[name] = false;
        emit Unpaused(name);
    }
}