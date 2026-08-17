pragma solidity >=0.5.0 <0.6.0;
import "../../libs/LibEIP712.sol";
contract LibEIP712Test is LibEIP712 {
    function _hashEIP712Message(bytes32 _hashStruct)
        public
        view
        returns (bytes32 _result)
    {
        _result = super.hashEIP712Message(_hashStruct);
    }
    function _recoverSignature(
        bytes32 _message,
        bytes memory _signature
    ) public view returns (address _signer) {
        _signer = super.recoverSignature(_message, _signature);
    }
}