pragma solidity ^0.5.16;
import "../Owned.sol";
import "../Pausable.sol";
contract TestablePausable is Owned, Pausable {
    uint public someValue;
    constructor(address _owner) public Owned(_owner) Pausable() {}
    function setSomeValue(uint _value) external notPaused {
        someValue = _value;
    }
}