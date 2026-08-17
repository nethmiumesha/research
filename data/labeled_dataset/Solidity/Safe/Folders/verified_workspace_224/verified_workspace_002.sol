pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
interface IApprovalRecipient {
    function receiveApproval(address _sender, uint256 _value, bytes _extraData) public;
}
contract TokenWithApproveAndCallMethod is StandardToken {
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public {
        require(approve(_spender, _value));
        IApprovalRecipient(_spender).receiveApproval(msg.sender, _value, _extraData);
    }
}