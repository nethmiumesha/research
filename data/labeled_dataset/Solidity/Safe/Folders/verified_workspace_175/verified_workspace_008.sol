pragma solidity 0.8.10;
interface IReferenceModule {
    function initializeReferenceModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external returns (bytes memory);
    function processComment(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) external;
    function processMirror(
        uint256 profileId,
        uint256 profileIdPointed,
        uint256 pubIdPointed
    ) external;
}