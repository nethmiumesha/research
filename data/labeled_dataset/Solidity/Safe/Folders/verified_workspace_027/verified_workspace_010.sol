pragma solidity 0.5.8;
import "../tokens/SecurityToken.sol";
contract MockSecurityTokenLogic is SecurityToken {
    event UpgradeEvent(uint256 _upgrade);
    uint256 public someValue;
    function upgrade(address _getterDelegate, uint256 _upgrade) external {
        getterDelegate = _getterDelegate;
        someValue = _upgrade;
        emit UpgradeEvent(_upgrade);
    }
    function initialize(address _getterDelegate, uint256 _someValue) public {
        require(!initialized, "Already initialized");
        getterDelegate = _getterDelegate;
        securityTokenVersion = SemanticVersion(3, 0, 0);
        updateFromRegistry();
        tokenFactory = msg.sender;
        initialized = true;
        someValue = _someValue;
    }
    function newFunction(uint256 _upgrade) external {
        emit UpgradeEvent(_upgrade);
    }
    function addModuleWithLabel(
        address ,
        bytes memory ,
        uint256 ,
        uint256 ,
        bytes32 ,
        bool
    )
        public
    {
        emit UpgradeEvent(0);
    }
}