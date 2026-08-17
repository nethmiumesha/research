pragma solidity ^0.8.22;
import {File, BytecodeSlice} from "./File.sol";
interface IFileStore {
    event Deployed();
    event FileCreated(
        string indexed indexedFilename,
        address indexed pointer,
        string filename,
        uint256 size,
        bytes metadata
    );
    error FileNotFound(string filename);
    error FilenameExists(string filename);
    error FileEmpty();
    error SliceEmpty(address pointer, uint32 start, uint32 end);
    error InvalidPointer(address pointer);
    function deployer() external view returns (address);
    function files(
        string memory filename
    ) external view returns (address pointer);
    function fileExists(string memory filename) external view returns (bool);
    function getPointer(
        string memory filename
    ) external view returns (address pointer);
    function getFile(
        string memory filename
    ) external view returns (File memory file);
    function createFile(
        string memory filename,
        string memory contents
    ) external returns (address pointer, File memory file);
    function createFile(
        string memory filename,
        string memory contents,
        bytes memory metadata
    ) external returns (address pointer, File memory file);
    function createFileFromChunks(
        string memory filename,
        string[] memory chunks
    ) external returns (address pointer, File memory file);
    function createFileFromChunks(
        string memory filename,
        string[] memory chunks,
        bytes memory metadata
    ) external returns (address pointer, File memory file);
    function createFileFromPointers(
        string memory filename,
        address[] memory pointers
    ) external returns (address pointer, File memory file);
    function createFileFromPointers(
        string memory filename,
        address[] memory pointers,
        bytes memory metadata
    ) external returns (address pointer, File memory file);
    function createFileFromSlices(
        string memory filename,
        BytecodeSlice[] memory slices
    ) external returns (address pointer, File memory file);
    function createFileFromSlices(
        string memory filename,
        BytecodeSlice[] memory slices,
        bytes memory metadata
    ) external returns (address pointer, File memory file);
}