pragma solidity 0.6.10;
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
library StringUtils {
    using SafeMath for uint;
    function strConcat(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory _ba = bytes(a);
        bytes memory _bb = bytes(b);
        string memory ab = new string(_ba.length.add(_bb.length));
        bytes memory strBytes = bytes(ab);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            strBytes[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            strBytes[k++] = _bb[i];
        }
        return string(strBytes);
    }
    function uint2str(uint i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint _i = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len.sub(1);
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}