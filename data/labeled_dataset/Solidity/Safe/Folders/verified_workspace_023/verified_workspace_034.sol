pragma solidity ^0.5.0;
import "../ownership/Ownable.sol";
contract OwnableInterfaceId {
    function getInterfaceId() public pure returns (bytes4) {
        Ownable i;
        return i.owner.selector ^ i.isOwner.selector ^ i.renounceOwnership.selector ^ i.transferOwnership.selector;
    }
}