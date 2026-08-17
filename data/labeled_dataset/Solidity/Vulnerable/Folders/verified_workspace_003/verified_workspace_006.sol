pragma solidity ^0.7.6;
pragma abicoder v2;
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "hardhat/console.sol";
contract PingPong is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint public endpoint;
    bool public pingsEnabled;
    event Ping(uint pings);
    uint public maxPings;
    uint public numPings;
    constructor(address _layerZeroEndpoint) {
        pingsEnabled = true;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        maxPings = 5;
    }
    function disable() external {
        pingsEnabled = false;
    }
    function ping(
        uint16 _dstChainId,
        address _dstPingPongAddr,
        uint pings
    ) public {
        require(address(this).balance > 0, "the balance of this contract is 0. pls send gas for message fees");
        require(pingsEnabled, "pingsEnabled is false. messages stopped");
        require(maxPings > pings, "maxPings has been reached, no more looping");
        emit Ping(pings);
        bytes memory payload = abi.encode(pings);
        uint16 version = 1;
        uint gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint messageFee, ) = endpoint.estimateFees(_dstChainId, address(this), payload, false, adapterParams);
        require(address(this).balance >= messageFee, "address(this).balance < messageFee. pls send gas for message fees");
        endpoint.send{value: messageFee}(
            _dstChainId,
            abi.encodePacked(_dstPingPongAddr),
            payload,
            payable(this),
            address(0x0),
            adapterParams
        );
    }
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        address fromAddress;
        assembly {
            fromAddress := mload(add(_fromAddress, 20))
        }
        uint pings = abi.decode(_payload, (uint));
        ++pings;
        numPings = pings;
        ping(_srcChainId, fromAddress, pings);
    }
    function setConfig(
        uint16,
        uint16 _dstChainId,
        uint _configType,
        bytes memory _config
    ) external override {
        endpoint.setConfig(_dstChainId, endpoint.getSendVersion(address(this)), _configType, _config);
    }
    function getConfig(
        uint16,
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
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
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
    }
    fallback() external payable {}
    receive() external payable {}
}