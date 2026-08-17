pragma solidity 0.5.8;
import "../tokens/SecurityToken.sol";
contract SecurityTokenMock is SecurityToken {
    function initialize(address _getterDelegate) public {
        super.initialize(_getterDelegate);
        securityTokenVersion = SemanticVersion(2, 2, 0);
    }
}