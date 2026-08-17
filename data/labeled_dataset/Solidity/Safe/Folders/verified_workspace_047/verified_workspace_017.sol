pragma solidity ^0.5.3;
import "./GroupsFunctionality.sol";
import "./interfaces/INodesData.sol";
import "./interfaces/ISchainsData.sol";
import "./interfaces/IConstants.sol";
contract SchainsFunctionalityInternal is GroupsFunctionality {
    event SchainNodes(
        string name,
        bytes32 groupIndex,
        uint[] nodesInGroup,
        uint32 time,
        uint gasSpend
    );
    constructor(
        string memory newExecutorName,
        string memory newDataName,
        address newContractsAddress
    )
        public
        GroupsFunctionality(newExecutorName, newDataName, newContractsAddress)
    {
    }
    function createGroupForSchain(
        string calldata schainName,
        bytes32 schainId,
        uint numberOfNodes,
        uint8 partOfNode) external allow(executorName)
    {
        address dataAddress = contractManager.contracts(keccak256(abi.encodePacked(dataName)));
        addGroup(schainId, numberOfNodes, bytes32(uint(partOfNode)));
        uint[] memory numberOfNodesInGroup = generateGroup(schainId);
        ISchainsData(dataAddress).setSchainPartOfNode(schainId, partOfNode);
        emit SchainNodes(
            schainName,
            schainId,
            numberOfNodesInGroup,
            uint32(block.timestamp),
            gasleft());
    }
    function getNodesDataFromTypeOfSchain(uint typeOfSchain) external view returns (uint numberOfNodes, uint8 partOfNode) {
        address constantsAddress = contractManager.contracts(keccak256(abi.encodePacked("Constants")));
        numberOfNodes = IConstants(constantsAddress).NUMBER_OF_NODES_FOR_SCHAIN();
        if (typeOfSchain == 1) {
            partOfNode = IConstants(constantsAddress).TINY_DIVISOR() / IConstants(constantsAddress).TINY_DIVISOR();
        } else if (typeOfSchain == 2) {
            partOfNode = IConstants(constantsAddress).TINY_DIVISOR() / IConstants(constantsAddress).SMALL_DIVISOR();
        } else if (typeOfSchain == 3) {
            partOfNode = IConstants(constantsAddress).TINY_DIVISOR() / IConstants(constantsAddress).MEDIUM_DIVISOR();
        } else if (typeOfSchain == 4) {
            partOfNode = 0;
            numberOfNodes = IConstants(constantsAddress).NUMBER_OF_NODES_FOR_TEST_SCHAIN();
        } else if (typeOfSchain == 5) {
            partOfNode = IConstants(constantsAddress).TINY_DIVISOR() / IConstants(constantsAddress).MEDIUM_TEST_DIVISOR();
            numberOfNodes = IConstants(constantsAddress).NUMBER_OF_NODES_FOR_MEDIUM_TEST_SCHAIN();
        } else {
            revert("Bad schain type");
        }
    }
    function replaceNode(
        uint nodeIndex,
        bytes32 groupHash
    )
        external
        allowThree(executorName, "SkaleDKG", "SchainsFunctionalityInternal")
        returns (uint newNodeIndex)
    {
        this.excludeNodeFromSchain(nodeIndex, groupHash);
        newNodeIndex = selectNodeToGroup(groupHash);
    }
    function selectNewNode(bytes32 groupHash) external allow(executorName) returns (uint newNodeIndex) {
        newNodeIndex = selectNodeToGroup(groupHash);
    }
    function removeNodeFromSchain(uint nodeIndex, bytes32 groupHash) external allow(executorName) {
        address schainsDataAddress = contractManager.contracts(keccak256(abi.encodePacked("SchainsData")));
        uint groupIndex = findSchainAtSchainsForNode(nodeIndex, groupHash);
        uint indexOfNode = findNode(groupHash, nodeIndex);
        IGroupsData(schainsDataAddress).removeNodeFromGroup(indexOfNode, groupHash);
        IGroupsData(schainsDataAddress).removeExceptionNode(groupHash, nodeIndex);
        ISchainsData(schainsDataAddress).removeSchainForNode(nodeIndex, groupIndex);
    }
    function excludeNodeFromSchain(uint nodeIndex, bytes32 groupHash)
        external
        allowThree(executorName, "SkaleDKG", "SchainsFunctionalityInternal")
    {
        address schainsDataAddress = contractManager.contracts(keccak256(abi.encodePacked("SchainsData")));
        uint groupIndex = findSchainAtSchainsForNode(nodeIndex, groupHash);
        uint indexOfNode = findNode(groupHash, nodeIndex);
        IGroupsData(schainsDataAddress).removeNodeFromGroup(indexOfNode, groupHash);
        ISchainsData(schainsDataAddress).removeSchainForNode(nodeIndex, groupIndex);
    }
    function isEnoughNodes(bytes32 groupIndex) external view returns (uint[] memory result) {
        IGroupsData groupsData = IGroupsData(contractManager.contracts(keccak256(abi.encodePacked(dataName))));
        INodesData nodesData = INodesData(contractManager.contracts(keccak256(abi.encodePacked("NodesData"))));
        uint8 space = uint8(uint(groupsData.getGroupData(groupIndex)));
        uint[] memory nodesWithFreeSpace = nodesData.getNodesWithFreeSpace(space);
        uint counter = 0;
        for (uint i = 0; i < nodesWithFreeSpace.length; i++) {
            if (groupsData.isExceptionNode(groupIndex, nodesWithFreeSpace[i]) || !nodesData.isNodeActive(nodesWithFreeSpace[i])) {
                counter++;
            }
        }
        if (counter < nodesWithFreeSpace.length) {
            result = new uint[](nodesWithFreeSpace.length - counter);
            counter = 0;
            for (uint i = 0; i < nodesWithFreeSpace.length; i++) {
                if (!groupsData.isExceptionNode(groupIndex, nodesWithFreeSpace[i]) && nodesData.isNodeActive(nodesWithFreeSpace[i])) {
                    result[counter] = nodesWithFreeSpace[i];
                    counter++;
                }
            }
        }
    }
    function findSchainAtSchainsForNode(uint nodeIndex, bytes32 schainId) public view returns (uint) {
        address dataAddress = contractManager.contracts(keccak256(abi.encodePacked(dataName)));
        uint length = ISchainsData(dataAddress).getLengthOfSchainsForNode(nodeIndex);
        for (uint i = 0; i < length; i++) {
            if (ISchainsData(dataAddress).schainsForNodes(nodeIndex, i) == schainId) {
                return i;
            }
        }
        return length;
    }
    function selectNodeToGroup(bytes32 groupIndex) internal returns (uint) {
        IGroupsData groupsData = IGroupsData(contractManager.contracts(keccak256(abi.encodePacked(dataName))));
        ISchainsData schainsData = ISchainsData(contractManager.contracts(keccak256(abi.encodePacked(dataName))));
        require(groupsData.isGroupActive(groupIndex), "Group is not active");
        uint8 space = uint8(uint(groupsData.getGroupData(groupIndex)));
        uint[] memory possibleNodes = this.isEnoughNodes(groupIndex);
        require(possibleNodes.length > 0, "No any free Nodes for rotation");
        uint nodeIndex;
        uint random = uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)), groupIndex)));
        do {
            uint index = random % possibleNodes.length;
            nodeIndex = possibleNodes[index];
            random = uint(keccak256(abi.encodePacked(random, nodeIndex)));
        } while (groupsData.isExceptionNode(groupIndex, nodeIndex));
        require(removeSpace(nodeIndex, space), "Could not remove space from nodeIndex");
        schainsData.addSchainForNode(nodeIndex, groupIndex);
        groupsData.setException(groupIndex, nodeIndex);
        groupsData.setNodeInGroup(groupIndex, nodeIndex);
        return nodeIndex;
    }
    function generateGroup(bytes32 groupIndex) internal returns (uint[] memory nodesInGroup) {
        IGroupsData groupsData = IGroupsData(contractManager.contracts(keccak256(abi.encodePacked(dataName))));
        ISchainsData schainsData = ISchainsData(contractManager.contracts(keccak256(abi.encodePacked(dataName))));
        require(groupsData.isGroupActive(groupIndex), "Group is not active");
        uint8 space = uint8(uint(groupsData.getGroupData(groupIndex)));
        nodesInGroup = new uint[](groupsData.getRecommendedNumberOfNodes(groupIndex));
        uint[] memory possibleNodes = this.isEnoughNodes(groupIndex);
        require(possibleNodes.length >= nodesInGroup.length, "Not enough nodes to create Schain");
        uint ignoringTail = 0;
        uint random = uint(keccak256(abi.encodePacked(uint(blockhash(block.number - 1)), groupIndex)));
        for (uint i = 0; i < nodesInGroup.length; ++i) {
            uint index = random % (possibleNodes.length - ignoringTail);
            uint node = possibleNodes[index];
            nodesInGroup[i] = node;
            swap(possibleNodes, index, possibleNodes.length - ignoringTail - 1);
            ++ignoringTail;
            groupsData.setException(groupIndex, node);
            schainsData.addSchainForNode(node, groupIndex);
            require(removeSpace(node, space), "Could not remove space from Node");
        }
        groupsData.setNodesInGroup(groupIndex, nodesInGroup);
        emit GroupGenerated(
            groupIndex,
            nodesInGroup,
            uint32(block.timestamp),
            gasleft());
    }
    function removeSpace(uint nodeIndex, uint8 space) internal returns (bool) {
        address nodesDataAddress = contractManager.contracts(keccak256(abi.encodePacked("NodesData")));
        return INodesData(nodesDataAddress).removeSpaceFromNode(nodeIndex, space);
    }
}