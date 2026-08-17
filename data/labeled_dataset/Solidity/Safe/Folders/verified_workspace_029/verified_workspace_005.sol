pragma solidity >=0.5.0 <0.6.0;
import "../../libs/NoteUtils.sol";
contract NoteUtilsTest {
    using NoteUtils for bytes;
    function getLength(bytes memory _proofOutputsOrNotes) public pure returns (
        uint len
    ) {
        return _proofOutputsOrNotes.getLength();
    }
    function get(bytes memory _proofOutputsOrNotes, uint _i) public pure returns (
        bytes memory out
    ) {
        return _proofOutputsOrNotes.get(_i);
    }
    function extractProofOutput(bytes memory _proofOutput) public pure returns (
        bytes memory inputNotes,
        bytes memory outputNotes,
        address publicOwner,
        int256 publicValue
    ) {
        return _proofOutput.extractProofOutput();
    }
    function extractChallenge(bytes memory _proofOutput) public pure returns (
        bytes32 challenge
    ) {
        return _proofOutput.extractChallenge();
    }
    function extractNote(bytes memory _note) public pure returns (
        address owner,
        bytes32 noteHash,
        bytes memory metadata
    ) {
        return _note.extractNote();
    }
    function getNoteType(bytes memory _note) public pure returns (
        uint256 noteType
    ) {
        return _note.getNoteType();
    }
}