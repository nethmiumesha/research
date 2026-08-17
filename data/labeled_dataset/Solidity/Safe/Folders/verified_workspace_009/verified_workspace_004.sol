pragma solidity 0.7.5;
import "../../VersionableBridge.sol";
contract OmnibridgeInfo is VersionableBridge {
    event TokensBridgingInitiated(
        address indexed token,
        address indexed sender,
        uint256 value,
        bytes32 indexed messageId
    );
    event TokensBridged(address indexed token, address indexed recipient, uint256 value, bytes32 indexed messageId);
    function getBridgeInterfacesVersion()
        external
        pure
        override
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (3, 0, 0);
    }
    function getBridgeMode() external pure override returns (bytes4 _data) {
        return 0xb1516c26;
    }
}