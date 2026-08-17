pragma solidity >= 0.5.0 <0.6.0;
library VersioningUtils {
    function getVersionComponents(uint24 version) internal pure returns (uint8 first, uint8 second, uint8 third) {
        assembly {
            third := and(version, 0xff)
            second := and(div(version, 0x100), 0xff)
            first := and(div(version, 0x10000), 0xff)
        }
        return (first, second, third);
    }
}