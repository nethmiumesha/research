pragma solidity 0.5.8;
import "../tokens/STGetter.sol";
contract MockSTGetter is STGetter {
    using SafeMath for uint256;
    event UpgradeEvent(uint256 _upgrade);
    function newGetter(uint256 _upgrade) public {
        emit UpgradeEvent(_upgrade);
    }
}