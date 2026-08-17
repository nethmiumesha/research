pragma solidity >=0.5.0 <0.6.0;
contract LibEIP712Malleable {
    string constant internal EIP712_DOMAIN_NAME = "AZTEC_CRYPTOGRAPHY_ENGINE";
    string constant internal EIP712_DOMAIN_VERSION = "1";
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
            "string name,",
            "string version,",
            "address verifyingContract",
        ")"
    ));
    bytes32 public EIP712_DOMAIN_HASH;
    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encode(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            address(this)
        ));
    }
    function hashEIP712Message(bytes32 _hashStruct)
        internal
        view
        returns (bytes32 _result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;
        assembly {
            let memPtr := mload(0x40)
            mstore(0x00, 0x1901)
            mstore(0x20, eip712DomainHash)
            mstore(0x40, _hashStruct)
            _result := keccak256(0x1e, 0x42)
            mstore(0x40, memPtr)
        }
    }
    function recoverSignature(
        bytes32 _message,
        bytes memory _signature
    ) internal view returns (address _signer) {
        bool result;
        assembly {
            let byteLength := mload(_signature)
            mstore(_signature, _message)
            let v := mload(add(_signature, 0x60))
            let s := mload(add(_signature, 0x40))
            v := shr(248, v)
            mstore(add(_signature, 0x60), mload(add(_signature, 0x40)))
            mstore(add(_signature, 0x40), mload(add(_signature, 0x20)))
            mstore(add(_signature, 0x20), v)
            result := and(
                and(
                    eq(byteLength, 0x41),
                    or(eq(v, 27), eq(v, 28))
                ),
                staticcall(gas, 0x01, _signature, 0x80, _signature, 0x20)
            )
            switch eq(_message, mload(_signature))
            case 0 {
                _signer := mload(_signature)
            }
            mstore(_signature, byteLength)
        }
        if (!(result && (_signer != address(0x0)))) {
            require(_signer != address(0x0), "signer address cannot be 0");
            require(result, "signature recovery failed");
        }
    }
}