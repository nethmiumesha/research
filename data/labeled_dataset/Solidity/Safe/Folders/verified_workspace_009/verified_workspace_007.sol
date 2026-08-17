pragma solidity 0.7.5;
import "../upgradeability/EternalStorage.sol";
import "../interfaces/IUpgradeabilityOwnerStorage.sol";
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202;
    event OwnershipTransferred(address previousOwner, address newOwner);
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
    function _onlyOwner() internal view {
        require(msg.sender == owner());
    }
    modifier onlyRelevantSender() {
        (bool isProxy, bytes memory returnData) =
            address(this).staticcall(abi.encodeWithSelector(UPGRADEABILITY_OWNER));
        require(
            !isProxy ||
                (returnData.length == 32 && msg.sender == abi.decode(returnData, (address))) ||
                msg.sender == address(this)
        );
        _;
    }
    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }
    function transferOwnership(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}