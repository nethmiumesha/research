pragma solidity 0.5.8;
import "../SecurityTokenRegistry.sol";
contract SecurityTokenRegistryMock is SecurityTokenRegistry {
    uint256 public someValue;
    function changeTheFee(uint256 _newFee) public {
        set(STLAUNCHFEE, _newFee);
    }
    function configure(uint256 _someValue) public {
        someValue = _someValue;
    }
}