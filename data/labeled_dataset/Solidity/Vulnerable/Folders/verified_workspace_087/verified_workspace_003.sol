pragma solidity ^0.8.0;
import "../libraries/DateString.sol";
contract TestDate {
    string public testString = "Tester";
    function encodeTimestamp(uint256 timestamp)
        external
        returns (string memory)
    {
        DateString.timestampToDateString(timestamp, testString);
        return testString;
    }
    function encodePrefixTimestamp(string calldata prefix, uint256 timestamp)
        external
        returns (string memory)
    {
        DateString.encodeAndWriteTimestamp(prefix, timestamp, testString);
        return testString;
    }
}