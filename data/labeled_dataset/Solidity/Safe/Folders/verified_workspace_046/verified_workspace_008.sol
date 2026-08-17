pragma solidity 0.6.10;
import "../SkaleToken.sol";
contract SkaleTokenInternalTester is SkaleToken {
    constructor(address contractManagerAddress, address[] memory defOps) public
    SkaleToken(contractManagerAddress, defOps)
    { }
    function getMsgData() external view returns (bytes memory) {
        return _msgData();
    }
}