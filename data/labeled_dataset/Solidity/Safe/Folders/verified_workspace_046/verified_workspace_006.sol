pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;
import "../SkaleDKG.sol";
contract SkaleDKGTester is SkaleDKG {
    function setSuccesfulDKGPublic(bytes32 schainId) external {
        _setSuccesfulDKG(schainId);
    }
}