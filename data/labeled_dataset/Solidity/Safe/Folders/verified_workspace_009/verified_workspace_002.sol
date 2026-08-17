pragma solidity 0.7.5;
import "../../../interfaces/IAMB.sol";
import "../OwnableModule.sol";
import "../../BasicOmnibridge.sol";
contract SelectorTokenGasLimitManager is OwnableModule {
    IAMB public immutable bridge;
    uint256 internal defaultGasLimit;
    mapping(bytes4 => uint256) internal selectorGasLimit;
    mapping(bytes4 => mapping(address => uint256)) internal selectorTokenGasLimit;
    constructor(
        IAMB _bridge,
        address _owner,
        uint256 _gasLimit
    ) OwnableModule(_owner) {
        require(_gasLimit <= _bridge.maxGasPerTx());
        bridge = _bridge;
        defaultGasLimit = _gasLimit;
    }
    modifier validGasLimit(uint256 _gasLimit) {
        require(_gasLimit <= bridge.maxGasPerTx());
        _;
    }
    modifier validGasLimits(uint256 _length, uint256[] calldata _gasLimits) {
        require(_gasLimits.length == _length);
        uint256 maxGasLimit = bridge.maxGasPerTx();
        for (uint256 i = 0; i < _length; i++) {
            require(_gasLimits[i] <= maxGasLimit);
        }
        _;
    }
    function setRequestGasLimit(uint256 _gasLimit) external onlyOwner validGasLimit(_gasLimit) {
        defaultGasLimit = _gasLimit;
    }
    function setRequestGasLimit(bytes4 _selector, uint256 _gasLimit) external onlyOwner validGasLimit(_gasLimit) {
        selectorGasLimit[_selector] = _gasLimit;
    }
    function setRequestGasLimit(
        bytes4 _selector,
        address _token,
        uint256 _gasLimit
    ) external onlyOwner validGasLimit(_gasLimit) {
        selectorTokenGasLimit[_selector][_token] = _gasLimit;
    }
    function requestGasLimit() public view returns (uint256) {
        return defaultGasLimit;
    }
    function requestGasLimit(bytes4 _selector) public view returns (uint256) {
        return selectorGasLimit[_selector];
    }
    function requestGasLimit(bytes4 _selector, address _token) public view returns (uint256) {
        return selectorTokenGasLimit[_selector][_token];
    }
    function requestGasLimit(bytes memory _data) external view returns (uint256) {
        bytes4 selector;
        address token;
        assembly {
            selector := shl(224, mload(add(_data, 4)))
            token := mload(add(_data, 36))
        }
        uint256 gasLimit = selectorTokenGasLimit[selector][token];
        if (gasLimit == 0) {
            gasLimit = selectorGasLimit[selector];
            if (gasLimit == 0) {
                gasLimit = defaultGasLimit;
            }
        }
        return gasLimit;
    }
    function setCommonRequestGasLimits(uint256[] calldata _gasLimits) external onlyOwner validGasLimits(7, _gasLimits) {
        require(_gasLimits[1] >= _gasLimits[0]);
        require(_gasLimits[3] >= _gasLimits[2]);
        require(_gasLimits[5] >= _gasLimits[4]);
        require(_gasLimits[0] >= _gasLimits[2]);
        require(_gasLimits[1] >= _gasLimits[3]);
        selectorGasLimit[BasicOmnibridge.deployAndHandleBridgedTokens.selector] = _gasLimits[0];
        selectorGasLimit[BasicOmnibridge.deployAndHandleBridgedTokensAndCall.selector] = _gasLimits[1];
        selectorGasLimit[BasicOmnibridge.handleBridgedTokens.selector] = _gasLimits[2];
        selectorGasLimit[BasicOmnibridge.handleBridgedTokensAndCall.selector] = _gasLimits[3];
        selectorGasLimit[BasicOmnibridge.handleNativeTokens.selector] = _gasLimits[4];
        selectorGasLimit[BasicOmnibridge.handleNativeTokensAndCall.selector] = _gasLimits[5];
        selectorGasLimit[FailedMessagesProcessor.fixFailedMessage.selector] = _gasLimits[6];
    }
    function setBridgedTokenRequestGasLimits(address _token, uint256[] calldata _gasLimits)
        external
        onlyOwner
        validGasLimits(2, _gasLimits)
    {
        require(_gasLimits[1] >= _gasLimits[0]);
        selectorTokenGasLimit[BasicOmnibridge.handleNativeTokens.selector][_token] = _gasLimits[0];
        selectorTokenGasLimit[BasicOmnibridge.handleNativeTokensAndCall.selector][_token] = _gasLimits[1];
    }
    function setNativeTokenRequestGasLimits(address _token, uint256[] calldata _gasLimits)
        external
        onlyOwner
        validGasLimits(4, _gasLimits)
    {
        require(_gasLimits[1] >= _gasLimits[0]);
        require(_gasLimits[3] >= _gasLimits[2]);
        require(_gasLimits[0] >= _gasLimits[2]);
        require(_gasLimits[1] >= _gasLimits[3]);
        selectorTokenGasLimit[BasicOmnibridge.deployAndHandleBridgedTokens.selector][_token] = _gasLimits[0];
        selectorTokenGasLimit[BasicOmnibridge.deployAndHandleBridgedTokensAndCall.selector][_token] = _gasLimits[1];
        selectorTokenGasLimit[BasicOmnibridge.handleBridgedTokens.selector][_token] = _gasLimits[2];
        selectorTokenGasLimit[BasicOmnibridge.handleBridgedTokensAndCall.selector][_token] = _gasLimits[3];
    }
}