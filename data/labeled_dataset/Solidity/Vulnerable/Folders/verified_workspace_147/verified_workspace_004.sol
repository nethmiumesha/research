pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
contract BoringOwnableUpgradeableData {
    address public owner;
    address public pendingOwner;
}
abstract contract BoringOwnableUpgradeableV2 is BoringOwnableUpgradeableData, Initializable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __BoringOwnableV2_init(address _owner) internal onlyInitializing {
        owner = _owner;
    }
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            require(newOwner != address(0) || renounce, "Ownable: zero address");
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = newOwner;
        }
    }
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    uint256[48] private __gap;
}