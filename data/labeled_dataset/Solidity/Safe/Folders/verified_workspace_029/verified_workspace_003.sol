pragma solidity >= 0.5.0 <0.6.0;
import "../../libs/MetaDataUtils.sol";
contract MetaDataUtilsTest {
    using MetaDataUtils for bytes;
    function extractAddress(bytes memory metaData, uint256 addressPos) public pure returns (address desiredAddress) {
        return metaData.extractAddress(addressPos);
    }
}