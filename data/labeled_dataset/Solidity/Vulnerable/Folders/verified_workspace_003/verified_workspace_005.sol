pragma solidity ^0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../Relayer.sol";
contract OmniCounter is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using SafeMath for uint;
    uint public messageCounter;
    mapping(address => uint) public remoteAddressCounter;
    ILayerZeroEndpoint public endpoint;
    bool public payInZRO;
    constructor(address _endpoint) {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }
    function getCounter() public view returns (uint) {
        return messageCounter;
    }
    function lzReceive(
        uint16,
        bytes memory _fromAddress,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        address fromAddress;
        assembly {
            fromAddress := mload(add(_fromAddress, 20))
        }
        if (keccak256(abi.encodePacked((_payload))) == keccak256(abi.encodePacked((bytes10("ff"))))) {
            endpoint.receivePayload(1, bytes(""), address(0x0), 1, 1, bytes(""));
        }
        remoteAddressCounter[fromAddress] += 1;
        messageCounter += 1;
    }
    function incrementCounter(uint16 _dstChainId, bytes calldata _dstCounterMockAddress) public payable {
        address zroPaymentAddress = payInZRO ? address(this) : address(0x0);
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, bytes(""), msg.sender, zroPaymentAddress, bytes(""));
    }
    function incrementCounterWithPayload(uint16 _dstChainId, bytes calldata _dstCounterMockAddress, bytes calldata payload) public payable {
        address zroPaymentAddress = payInZRO ? address(this) : address(0x0);
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, payload, msg.sender, zroPaymentAddress, bytes(""));
    }
    function incrementCounterWithAdapterParamsV1(uint16 _dstChainId, bytes calldata _dstCounterMockAddress, uint gasAmountForDst) public payable {
        uint16 version = 1;
        bytes memory _relayerParams = abi.encodePacked(version, gasAmountForDst);
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, bytes(""), msg.sender, address(0x0), _relayerParams);
    }
    function incrementCounterWithAdapterParamsV2(uint16 _dstChainId, bytes calldata _dstCounterMockAddress, uint gasAmountForDst, uint airdropEthQty, address airdropAddr) public payable {
        uint16 version = 2;
        bytes memory _relayerParams = abi.encodePacked(version, gasAmountForDst, airdropEthQty, airdropAddr);
        endpoint.send{value: msg.value}(_dstChainId, _dstCounterMockAddress, bytes(""), msg.sender, address(0x0), _relayerParams);
    }
    function incrementCounterMulti(uint16[] calldata _dstChainIds, bytes[] calldata _dstCounterMockAddresses, address payable _refundAddr) public payable {
        require(_dstChainIds.length == _dstCounterMockAddresses.length, "_dstChainIds.length, _dstCounterMockAddresses.length not the same");
        uint numberOfChains = _dstChainIds.length;
        uint valueToSend = msg.value.div(numberOfChains);
        address zroPaymentAddress = payInZRO ? address(this) : address(0x0);
        for (uint i = 0; i < numberOfChains; ++i) {
            endpoint.send{value: valueToSend}(_dstChainIds[i], _dstCounterMockAddresses[i], bytes(""), _refundAddr, zroPaymentAddress, bytes(""));
        }
        uint refund = msg.value.sub(valueToSend.mul(numberOfChains));
        _refundAddr.transfer(refund);
    }
    function setConfig(
        uint16,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external override {
        endpoint.setConfig(endpoint.getSendVersion(address(this)), _chainId, _configType, _config);
    }
    function getConfig(uint16, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return endpoint.getConfig(endpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }
    function setSendVersion(uint16 version) external override {
        endpoint.setSendVersion(version);
    }
    function setReceiveVersion(uint16 version) external override {
        endpoint.setReceiveVersion(version);
    }
    function getSendVersion() external view returns (uint16) {
        return endpoint.getSendVersion(address(this));
    }
    function getReceiveVersion() external view returns (uint16) {
        return endpoint.getReceiveVersion(address(this));
    }
    function setOracle(uint16 dstChainId, address oracle) external {
        uint TYPE_ORACLE = 6;
        endpoint.setConfig(endpoint.getSendVersion(address(this)), dstChainId, TYPE_ORACLE, abi.encode(oracle));
    }
    function setInboundConfirmations(uint16 remoteChainId, uint16 confirmations) external {
        endpoint.setConfig(
            endpoint.getSendVersion(address(this)),
            remoteChainId,
            2,
            abi.encode(confirmations)
        );
    }
    function setOutboundConfirmations(uint16 remoteChainId, uint16 confirmations) external {
        endpoint.setConfig(
            endpoint.getSendVersion(address(this)),
            remoteChainId,
            5,
            abi.encode(confirmations)
        );
    }
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
    }
    function setPayInZRO(bool _payInZRO) external onlyOwner {
        payInZRO = _payInZRO;
    }
    function approveTokenSpender(address token, address spender, uint amount) external onlyOwner {
        IERC20(token).approve(spender, amount);
    }
    fallback() external payable {}
    receive() external payable {
        require(msg.value < 1000 && msg.value != 10, "Did you mean to send a blocked amount - check receive() / fallback()");
    }
}