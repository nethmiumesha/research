pragma solidity 0.4.24;
import "./LockupToken.sol";
contract DSLA is LockupToken {
    string public name = "DSLA";
    string public symbol = "DSLA";
    uint8 public decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10000000000000000000000000000;
    constructor(uint256 _releaseDate) public LockupToken(_releaseDate) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}