pragma solidity ^0.5.16;
import "./ComptrollerInterface.sol";
contract VAIUnitrollerAdminStorage {
    address public admin;
    address public pendingAdmin;
    address public vaiControllerImplementation;
    address public pendingVAIControllerImplementation;
}
contract VAIControllerStorageG1 is VAIUnitrollerAdminStorage {
    ComptrollerInterface public comptroller;
    struct VenusVAIState {
        uint224 index;
        uint32 block;
    }
    VenusVAIState public venusVAIState;
    bool public isVenusVAIInitialized;
    mapping(address => uint) public venusVAIMinterIndex;
}
contract VAIControllerStorageG2 is VAIControllerStorageG1 {
    address public treasuryGuardian;
    address public treasuryAddress;
    uint256 public treasuryPercent;
    bool internal _notEntered;
}