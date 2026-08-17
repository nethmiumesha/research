pragma solidity ^0.5.3;
import "./GroupsData.sol";
import "./interfaces/ISchainsData.sol";
contract SchainsData is ISchainsData, GroupsData {
    struct Schain {
        string name;
        address owner;
        uint indexInOwnerList;
        uint8 partOfNode;
        uint lifetime;
        uint32 startDate;
        uint deposit;
        uint64 index;
    }
    mapping (bytes32 => Schain) public schains;
    mapping (address => bytes32[]) public schainIndexes;
    mapping (uint => bytes32[]) public schainsForNodes;
    mapping (uint => uint[]) public holesForNodes;
    bytes32[] public schainsAtSystem;
    uint64 public numberOfSchains = 0;
    uint public sumOfSchainsResources = 0;
    constructor(string memory newExecutorName, address newContractsAddress) GroupsData(newExecutorName, newContractsAddress) public {
    }
    function initializeSchain(
        string calldata name,
        address from,
        uint lifetime,
        uint deposit) external allow("SchainsFunctionality")
    {
        bytes32 schainId = keccak256(abi.encodePacked(name));
        schains[schainId].name = name;
        schains[schainId].owner = from;
        schains[schainId].startDate = uint32(block.timestamp);
        schains[schainId].lifetime = lifetime;
        schains[schainId].deposit = deposit;
        schains[schainId].index = numberOfSchains;
        numberOfSchains++;
        schainsAtSystem.push(schainId);
    }
    function setSchainIndex(bytes32 schainId, address from) external allow("SchainsFunctionality") {
        schains[schainId].indexInOwnerList = schainIndexes[from].length;
        schainIndexes[from].push(schainId);
    }
    function addSchainForNode(uint nodeIndex, bytes32 schainId) external allow(executorName) {
        if (holesForNodes[nodeIndex].length == 0) {
            schainsForNodes[nodeIndex].push(schainId);
        } else {
            schainsForNodes[nodeIndex][holesForNodes[nodeIndex][0]] = schainId;
            uint min = uint(-1);
            uint index = 0;
            for (uint i = 1; i < holesForNodes[nodeIndex].length; i++) {
                if (min > holesForNodes[nodeIndex][i]) {
                    min = holesForNodes[nodeIndex][i];
                    index = i;
                }
            }
            if (min == uint(-1)) {
                delete holesForNodes[nodeIndex];
            } else {
                holesForNodes[nodeIndex][0] = min;
                holesForNodes[nodeIndex][index] = holesForNodes[nodeIndex][holesForNodes[nodeIndex].length - 1];
                delete holesForNodes[nodeIndex][holesForNodes[nodeIndex].length - 1];
                holesForNodes[nodeIndex].length--;
            }
        }
    }
    function setSchainPartOfNode(bytes32 schainId, uint8 partOfNode) external allow(executorName) {
        schains[schainId].partOfNode = partOfNode;
        if (partOfNode > 0) {
            sumOfSchainsResources += (128 / partOfNode) * groups[schainId].nodesInGroup.length;
        }
    }
    function changeLifetime(bytes32 schainId, uint lifetime, uint deposit) external allow("SchainsFunctionality") {
        schains[schainId].deposit += deposit;
        schains[schainId].lifetime += lifetime;
    }
    function removeSchain(bytes32 schainId, address from) external allow("SchainsFunctionality") {
        uint length = schainIndexes[from].length;
        uint index = schains[schainId].indexInOwnerList;
        if (index != length - 1) {
            bytes32 lastSchainId = schainIndexes[from][length - 1];
            schains[lastSchainId].indexInOwnerList = index;
            schainIndexes[from][index] = lastSchainId;
        }
        delete schainIndexes[from][length - 1];
        schainIndexes[from].length--;
        for (uint i = 0; i + 1 < schainsAtSystem.length; i++) {
            if (schainsAtSystem[i] == schainId) {
                schainsAtSystem[i] = schainsAtSystem[schainsAtSystem.length - 1];
                break;
            }
        }
        delete schainsAtSystem[schainsAtSystem.length - 1];
        schainsAtSystem.length--;
        delete schains[schainId];
        numberOfSchains--;
    }
    function removeSchainForNode(uint nodeIndex, uint schainIndex) external allow("SchainsFunctionalityInternal") {
        uint length = schainsForNodes[nodeIndex].length;
        if (schainIndex == length - 1) {
            delete schainsForNodes[nodeIndex][length - 1];
            schainsForNodes[nodeIndex].length--;
        } else {
            schainsForNodes[nodeIndex][schainIndex] = bytes32(0);
            if (holesForNodes[nodeIndex].length > 0 && holesForNodes[nodeIndex][0] > schainIndex) {
                uint hole = holesForNodes[nodeIndex][0];
                holesForNodes[nodeIndex][0] = schainIndex;
                holesForNodes[nodeIndex].push(hole);
            } else {
                holesForNodes[nodeIndex].push(schainIndex);
            }
        }
    }
    function getSchains() external view returns (bytes32[] memory) {
        return schainsAtSystem;
    }
    function getSchainsPartOfNode(bytes32 schainId) external view returns (uint8) {
        return schains[schainId].partOfNode;
    }
    function getSchainListSize(address from) external view returns (uint) {
        return schainIndexes[from].length;
    }
    function getSchainIdsByAddress(address from) external view returns (bytes32[] memory) {
        return schainIndexes[from];
    }
    function getSchainIdsForNode(uint nodeIndex) external view returns (bytes32[] memory) {
        return schainsForNodes[nodeIndex];
    }
    function getLengthOfSchainsForNode(uint nodeIndex) external view returns (uint) {
        return schainsForNodes[nodeIndex].length;
    }
    function getSchainIdFromSchainName(string calldata schainName) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(schainName));
    }
    function getSchainOwner(bytes32 schainId) external view returns (address) {
        return schains[schainId].owner;
    }
    function isSchainNameAvailable(string calldata name) external view returns (bool) {
        bytes32 schainId = keccak256(abi.encodePacked(name));
        return schains[schainId].owner == address(0);
    }
    function isTimeExpired(bytes32 schainId) external view returns (bool) {
        return schains[schainId].startDate + schains[schainId].lifetime < block.timestamp;
    }
    function isOwnerAddress(address from, bytes32 schainId) external view returns (bool) {
        return schains[schainId].owner == from;
    }
}