pragma solidity 0.4.24;
import "../upgradeability/EternalStorage.sol";
contract Ownable is EternalStorage {
    event OwnershipTransferred(address previousOwner, address newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }
    function owner() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("owner"))];
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256(abi.encodePacked("owner"))] = newOwner;
    }
}