pragma solidity ^0.5.3;
import "./Permissions.sol";
import "./interfaces/IConstants.sol";
import "./interfaces/INodesData.sol";
import "./interfaces/ISchainsData.sol";
import "./interfaces/INodesFunctionality.sol";
import "./delegation/ValidatorService.sol";
contract NodesFunctionality is Permissions, INodesFunctionality {
    event NodeCreated(
        uint nodeIndex,
        address owner,
        string name,
        bytes4 ip,
        bytes4 publicIP,
        uint16 port,
        uint16 nonce,
        uint32 time,
        uint gasSpend
    );
    event WithdrawDepositFromNodeComplete(
        uint nodeIndex,
        address owner,
        uint deposit,
        uint32 time,
        uint gasSpend
    );
    event WithdrawDepositFromNodeInit(
        uint nodeIndex,
        address owner,
        uint32 startLeavingPeriod,
        uint32 time,
        uint gasSpend
    );
    constructor(address newContractsAddress) Permissions(newContractsAddress) public {
    }
    function createNode(address from, bytes calldata data) external allow("SkaleManager") returns (uint nodeIndex) {
        address nodesDataAddress = contractManager.getContract("NodesData");
        uint16 nonce;
        bytes4 ip;
        bytes4 publicIP;
        uint16 port;
        string memory name;
        bytes memory publicKey;
        (port, nonce, ip, publicIP) = fallbackDataConverter(data);
        (publicKey, name) = fallbackDataConverterPublicKeyAndName(data);
        require(ip != 0x0 && !INodesData(nodesDataAddress).nodesIPCheck(ip), "IP address is zero or is not available");
        require(!INodesData(nodesDataAddress).nodesNameCheck(keccak256(abi.encodePacked(name))), "Name has already registered");
        require(port > 0, "Port is zero");
        uint validatorId = ValidatorService(contractManager.getContract("ValidatorService")).getValidatorId(from);
        nodeIndex = INodesData(nodesDataAddress).addNode(
            from,
            name,
            ip,
            publicIP,
            port,
            publicKey,
            validatorId);
        emit NodeCreated(
            nodeIndex,
            from,
            name,
            ip,
            publicIP,
            port,
            nonce,
            uint32(block.timestamp),
            gasleft());
    }
    function removeNode(address from, uint nodeIndex) external allow("SkaleManager") {
        address nodesDataAddress = contractManager.getContract("NodesData");
        require(INodesData(nodesDataAddress).isNodeExist(from, nodeIndex), "Node does not exist for message sender");
        require(INodesData(nodesDataAddress).isNodeActive(nodeIndex), "Node is not Active");
        INodesData(nodesDataAddress).setNodeLeft(nodeIndex);
        INodesData(nodesDataAddress).removeNode(nodeIndex);
    }
    function removeNodeByRoot(uint nodeIndex) external allow("SkaleManager") {
        address nodesDataAddress = contractManager.getContract("NodesData");
        INodesData(nodesDataAddress).setNodeLeft(nodeIndex);
        INodesData(nodesDataAddress).removeNode(nodeIndex);
    }
    function initWithdrawDeposit(address from, uint nodeIndex) external allow("SkaleManager") returns (bool) {
        INodesData nodesData = INodesData(contractManager.getContract("NodesData"));
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        require(validatorService.validatorAddressExists(from), "Validator with such address doesn't exist");
        require(nodesData.isNodeExist(from, nodeIndex), "Node does not exist for message sender");
        require(nodesData.isNodeActive(nodeIndex), "Node is not Active");
        nodesData.setNodeLeaving(nodeIndex);
        emit WithdrawDepositFromNodeInit(
            nodeIndex,
            from,
            uint32(block.timestamp),
            uint32(block.timestamp),
            gasleft());
        return true;
    }
    function completeWithdrawDeposit(address from, uint nodeIndex) external allow("SkaleManager") {
        INodesData nodesData = INodesData(contractManager.getContract("NodesData"));
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        require(validatorService.validatorAddressExists(from), "Validator with such address doesn't exist");
        require(nodesData.isNodeExist(from, nodeIndex), "Node does not exist for message sender");
        require(nodesData.isNodeLeaving(nodeIndex), "Node is no Leaving");
        require(nodesData.isLeavingPeriodExpired(nodeIndex), "Leaving period has not expired");
        nodesData.setNodeLeft(nodeIndex);
        nodesData.removeNode(nodeIndex);
        emit WithdrawDepositFromNodeComplete(
            nodeIndex,
            from,
            0,
            uint32(block.timestamp),
            gasleft());
    }
    function fallbackDataConverter(bytes memory data)
        private
        pure
        returns (uint16, uint16, bytes4, bytes4 )
    {
        require(data.length > 77, "Incorrect bytes data config");
        bytes4 ip;
        bytes4 publicIP;
        bytes2 portInBytes;
        bytes2 nonceInBytes;
        assembly {
            portInBytes := mload(add(data, 33))
            nonceInBytes := mload(add(data, 35))
            ip := mload(add(data, 37))
            publicIP := mload(add(data, 41))
        }
        return (uint16(portInBytes), uint16(nonceInBytes), ip, publicIP);
    }
    function fallbackDataConverterPublicKeyAndName(bytes memory data) private pure returns (bytes memory, string memory) {
        require(data.length > 77, "Incorrect bytes data config");
        bytes32 firstPartPublicKey;
        bytes32 secondPartPublicKey;
        bytes memory publicKey = new bytes(64);
        assembly {
            firstPartPublicKey := mload(add(data, 45))
            secondPartPublicKey := mload(add(data, 77))
        }
        for (uint8 i = 0; i < 32; i++) {
            publicKey[i] = firstPartPublicKey[i];
        }
        for (uint8 i = 0; i < 32; i++) {
            publicKey[i + 32] = secondPartPublicKey[i];
        }
        string memory name = new string(data.length - 77);
        for (uint i = 0; i < bytes(name).length; ++i) {
            bytes(name)[i] = data[77 + i];
        }
        return (publicKey, name);
    }
}