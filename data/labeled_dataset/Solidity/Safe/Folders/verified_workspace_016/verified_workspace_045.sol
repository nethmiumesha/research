pragma solidity ^0.6.0;
import "../GSN/Context.sol";
contract ReentrancyAttack is Context {
    function callSender(bytes4 data) public {
        (bool success,) = _msgSender().call(abi.encodeWithSelector(data));
        require(success, "ReentrancyAttack: failed call");
    }
}