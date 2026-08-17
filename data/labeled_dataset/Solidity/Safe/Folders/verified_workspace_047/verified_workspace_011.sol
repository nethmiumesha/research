pragma solidity ^0.5.3;
import "./Permissions.sol";
import "./interfaces/IConstants.sol";
import "./interfaces/INodesData.sol";
contract NodesData is INodesData, Permissions {
    enum NodeStatus {Active, Leaving, Left}
    struct Node {
        string name;
        bytes4 ip;
        bytes4 publicIP;
        uint16 port;
        bytes publicKey;
        uint32 startDate;
        uint32 leavingDate;
        uint32 lastRewardDate;
        NodeStatus status;
        uint validatorId;
    }
    struct CreatedNodes {
        mapping (uint => bool) isNodeExist;
        uint numberOfNodes;
    }
    struct SpaceManaging {
        uint8 freeSpace;
        uint indexInSpaceMap;
    }
    Node[] public nodes;
    SpaceManaging[] public spaceOfNodes;
    mapping (address => CreatedNodes) public nodeIndexes;
    mapping (bytes4 => bool) public nodesIPCheck;
    mapping (bytes32 => bool) public nodesNameCheck;
    mapping (bytes32 => uint) public nodesNameToIndex;
    mapping (uint8 => uint[]) public spaceToNodes;
    uint leavingPeriod;
    uint public numberOfActiveNodes = 0;
    uint public numberOfLeavingNodes = 0;
    uint public numberOfLeftNodes = 0;
    constructor(uint newLeavingPeriod, address newContractsAddress) Permissions(newContractsAddress) public {
        leavingPeriod = newLeavingPeriod;
    }
    function getNodesWithFreeSpace(uint8 freeSpace) external view returns (uint[] memory) {
        uint[] memory nodesWithFreeSpace = new uint[](this.countNodesWithFreeSpace(freeSpace));
        uint cursor = 0;
        for (uint8 i = freeSpace; i <= 128; ++i) {
            for (uint j = 0; j < spaceToNodes[i].length; j++) {
                nodesWithFreeSpace[cursor] = spaceToNodes[i][j];
                ++cursor;
            }
        }
        return nodesWithFreeSpace;
    }
    function countNodesWithFreeSpace(uint8 freeSpace) external view returns (uint count) {
        count = 0;
        for (uint8 i = freeSpace; i <= 128; ++i) {
            count += spaceToNodes[i].length;
        }
    }
    function addNode(
        address from,
        string calldata name,
        bytes4 ip,
        bytes4 publicIP,
        uint16 port,
        bytes calldata publicKey,
        uint validatorId
    )
        external
        allow("NodesFunctionality")
        returns (uint nodeIndex)
    {
        nodes.push(Node({
            name: name,
            ip: ip,
            publicIP: publicIP,
            port: port,
            publicKey: publicKey,
            startDate: uint32(block.timestamp),
            leavingDate: uint32(0),
            lastRewardDate: uint32(block.timestamp),
            status: NodeStatus.Active,
            validatorId: validatorId
        }));
        nodeIndex = nodes.length - 1;
        bytes32 nodeId = keccak256(abi.encodePacked(name));
        nodesIPCheck[ip] = true;
        nodesNameCheck[nodeId] = true;
        nodesNameToIndex[nodeId] = nodeIndex;
        nodeIndexes[from].isNodeExist[nodeIndex] = true;
        nodeIndexes[from].numberOfNodes++;
        spaceOfNodes.push(SpaceManaging({
            freeSpace: 128,
            indexInSpaceMap: spaceToNodes[128].length
        }));
        spaceToNodes[128].push(nodeIndex);
        numberOfActiveNodes++;
    }
    function setNodeLeaving(uint nodeIndex) external allow("NodesFunctionality") {
        nodes[nodeIndex].status = NodeStatus.Leaving;
        nodes[nodeIndex].leavingDate = uint32(block.timestamp);
        numberOfActiveNodes--;
        numberOfLeavingNodes++;
    }
    function setNodeLeft(uint nodeIndex) external allow("NodesFunctionality") {
        nodesIPCheck[nodes[nodeIndex].ip] = false;
        nodesNameCheck[keccak256(abi.encodePacked(nodes[nodeIndex].name))] = false;
        delete nodesNameToIndex[keccak256(abi.encodePacked(nodes[nodeIndex].name))];
        if (nodes[nodeIndex].status == NodeStatus.Active) {
            numberOfActiveNodes--;
        } else {
            numberOfLeavingNodes--;
        }
        nodes[nodeIndex].status = NodeStatus.Left;
        numberOfLeftNodes++;
    }
    function removeNode(uint nodeIndex) external allow("NodesFunctionality") {
        uint8 space = spaceOfNodes[nodeIndex].freeSpace;
        uint indexInArray = spaceOfNodes[nodeIndex].indexInSpaceMap;
        if (indexInArray < spaceToNodes[space].length - 1) {
            uint shiftedIndex = spaceToNodes[space][spaceToNodes[space].length - 1];
            spaceToNodes[space][indexInArray] = shiftedIndex;
            spaceOfNodes[shiftedIndex].indexInSpaceMap = indexInArray;
            spaceToNodes[space].length--;
        } else {
            spaceToNodes[space].length--;
        }
        delete spaceOfNodes[nodeIndex].freeSpace;
        delete spaceOfNodes[nodeIndex].indexInSpaceMap;
    }
    function removeSpaceFromNode(uint nodeIndex, uint8 space) external allow("SchainsFunctionalityInternal") returns (bool) {
        if (spaceOfNodes[nodeIndex].freeSpace < space) {
            return false;
        }
        if (space > 0) {
            moveNodeToNewSpaceMap(
                nodeIndex,
                spaceOfNodes[nodeIndex].freeSpace - space
            );
        }
        return true;
    }
    function addSpaceToNode(uint nodeIndex, uint8 space) external allow("SchainsFunctionality") {
        if (space > 0) {
            moveNodeToNewSpaceMap(
                nodeIndex,
                spaceOfNodes[nodeIndex].freeSpace + space
            );
        }
    }
    function changeNodeLastRewardDate(uint nodeIndex) external allow("SkaleManager") {
        nodes[nodeIndex].lastRewardDate = uint32(block.timestamp);
    }
    function isNodeExist(address from, uint nodeIndex) external view returns (bool) {
        return nodeIndexes[from].isNodeExist[nodeIndex];
    }
    function isLeavingPeriodExpired(uint nodeIndex) external view returns (bool) {
        return block.timestamp - nodes[nodeIndex].leavingDate >= leavingPeriod;
    }
    function isTimeForReward(uint nodeIndex) external view returns (bool) {
        address constantsAddress = contractManager.contracts(keccak256(abi.encodePacked("Constants")));
        return nodes[nodeIndex].lastRewardDate + IConstants(constantsAddress).rewardPeriod() <= block.timestamp;
    }
    function getNodeIP(uint nodeIndex) external view returns (bytes4) {
        return nodes[nodeIndex].ip;
    }
    function getNodePort(uint nodeIndex) external view returns (uint16) {
        return nodes[nodeIndex].port;
    }
    function getNodePublicKey(uint nodeIndex) external view returns (bytes memory) {
        return nodes[nodeIndex].publicKey;
    }
    function getNodeValidatorId(uint nodeIndex) external view returns (uint) {
        return nodes[nodeIndex].validatorId;
    }
    function isNodeLeaving(uint nodeIndex) external view returns (bool) {
        return nodes[nodeIndex].status == NodeStatus.Leaving;
    }
    function isNodeLeft(uint nodeIndex) external view returns (bool) {
        return nodes[nodeIndex].status == NodeStatus.Left;
    }
    function getNodeLastRewardDate(uint nodeIndex) external view returns (uint32) {
        return nodes[nodeIndex].lastRewardDate;
    }
    function getNodeNextRewardDate(uint nodeIndex) external view returns (uint32) {
        address constantsAddress = contractManager.contracts(keccak256(abi.encodePacked("Constants")));
        return nodes[nodeIndex].lastRewardDate + IConstants(constantsAddress).rewardPeriod();
    }
    function getNumberOfNodes() external view returns (uint) {
        return nodes.length;
    }
    function getNumberOnlineNodes() external view returns (uint) {
        return numberOfActiveNodes + numberOfLeavingNodes;
    }
    function getActiveNodeIPs() external view returns (bytes4[] memory activeNodeIPs) {
        activeNodeIPs = new bytes4[](numberOfActiveNodes);
        uint indexOfActiveNodeIPs = 0;
        for (uint indexOfNodes = 0; indexOfNodes < nodes.length; indexOfNodes++) {
            if (isNodeActive(indexOfNodes)) {
                activeNodeIPs[indexOfActiveNodeIPs] = nodes[indexOfNodes].ip;
                indexOfActiveNodeIPs++;
            }
        }
    }
    function getActiveNodesByAddress() external view returns (uint[] memory activeNodesByAddress) {
        activeNodesByAddress = new uint[](nodeIndexes[msg.sender].numberOfNodes);
        uint indexOfActiveNodesByAddress = 0;
        for (uint indexOfNodes = 0; indexOfNodes < nodes.length; indexOfNodes++) {
            if (nodeIndexes[msg.sender].isNodeExist[indexOfNodes] && isNodeActive(indexOfNodes)) {
                activeNodesByAddress[indexOfActiveNodesByAddress] = indexOfNodes;
                indexOfActiveNodesByAddress++;
            }
        }
    }
    function getActiveNodeIds() external view returns (uint[] memory activeNodeIds) {
        activeNodeIds = new uint[](numberOfActiveNodes);
        uint indexOfActiveNodeIds = 0;
        for (uint indexOfNodes = 0; indexOfNodes < nodes.length; indexOfNodes++) {
            if (isNodeActive(indexOfNodes)) {
                activeNodeIds[indexOfActiveNodeIds] = indexOfNodes;
                indexOfActiveNodeIds++;
            }
        }
    }
    function getValidatorId(uint nodeIndex) external view returns (uint) {
        require(nodeIndex < nodes.length, "Node does not exist");
        return nodes[nodeIndex].validatorId;
    }
    function isNodeActive(uint nodeIndex) public view returns (bool) {
        return nodes[nodeIndex].status == NodeStatus.Active;
    }
    function moveNodeToNewSpaceMap(uint nodeIndex, uint8 newSpace) internal {
        uint8 previousSpace = spaceOfNodes[nodeIndex].freeSpace;
        uint indexInArray = spaceOfNodes[nodeIndex].indexInSpaceMap;
        if (indexInArray < spaceToNodes[previousSpace].length - 1) {
            uint shiftedIndex = spaceToNodes[previousSpace][spaceToNodes[previousSpace].length - 1];
            spaceToNodes[previousSpace][indexInArray] = shiftedIndex;
            spaceOfNodes[shiftedIndex].indexInSpaceMap = indexInArray;
            spaceToNodes[previousSpace].length--;
        } else {
            spaceToNodes[previousSpace].length--;
        }
        spaceToNodes[newSpace].push(nodeIndex);
        spaceOfNodes[nodeIndex].freeSpace = newSpace;
        spaceOfNodes[nodeIndex].indexInSpaceMap = spaceToNodes[newSpace].length - 1;
    }
}