pragma solidity ^0.5.3;
interface INodesData {
    function nodesIPCheck(bytes4 ip) external view returns (bool);
    function nodesNameCheck(bytes32 name) external view returns (bool);
    function isNodeExist(address from, uint nodeIndex) external view returns (bool);
    function isNodeActive(uint nodeIndex) external view returns (bool);
    function isNodeLeaving(uint nodeIndex) external view returns (bool);
    function isNodeLeft(uint nodeIndex) external view returns (bool);
    function isLeavingPeriodExpired(uint nodeIndex) external view returns (bool);
    function isTimeForReward(uint nodeIndex) external view returns (bool);
    function addNode(
        address from,
        string calldata name,
        bytes4 ip,
        bytes4 publicIP,
        uint16 port,
        bytes calldata publicKey,
        uint validatorId)
    external returns (uint);
    function setNodeLeaving(uint nodeIndex) external;
    function setNodeLeft(uint nodeIndex) external;
    function numberOfActiveNodes() external view returns (uint);
    function numberOfLeavingNodes() external view returns (uint);
    function getNumberOnlineNodes() external view returns (uint);
    function changeNodeLastRewardDate(uint nodeIndex) external;
    function getNodeLastRewardDate(uint nodeIndex) external view returns (uint32);
    function addSpaceToNode(uint nodeIndex, uint8 space) external;
    function removeNode(uint nodeIndex) external;
    function removeSpaceFromNode(uint nodeIndex, uint8 space) external returns (bool);
    function countNodesWithFreeSpace(uint8 freeSpace) external view returns (uint count);
    function getNumberOfNodes() external view returns (uint);
    function getNodeIP(uint nodeIndex) external view returns (bytes4);
    function getNodeNextRewardDate(uint nodeIndex) external view returns (uint32);
    function getNodePublicKey(uint nodeIndex) external view returns (bytes memory);
    function getNodeValidatorId(uint nodeIndex) external view returns (uint);
    function getActiveNodeIds() external view returns (uint[] memory activeNodeIds);
    function getNodesWithFreeSpace(uint8 freeSpace) external view returns (uint[] memory);
}