pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
contract TestGuestList {
    address public vault;
    address public bouncer;
    mapping(address => bool) public guests;
    constructor() public {
        bouncer = msg.sender;
    }
    function setGuests(address[] calldata _guests, bool[] calldata _invited) external {
        assert(msg.sender == bouncer);
        assert(_guests.length == _invited.length);
        for (uint256 i = 0; i < _guests.length; i++) {
            if (_guests[i] == address(0)) {
                break;
            }
            guests[_guests[i]] = _invited[i];
        }
    }
    function authorized(address _guest, uint256 _amount) external view returns (bool) {
        return guests[_guest];
    }
}