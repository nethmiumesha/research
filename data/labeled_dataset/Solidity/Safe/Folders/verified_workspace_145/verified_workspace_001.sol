pragma solidity 0.4.25;
import "./State.sol";
contract EternalStorage is State {
    constructor(address _owner, address _associatedContract)
        State(_owner, _associatedContract)
        public
    {
    }
    mapping(bytes32 => uint) UIntStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => int) IntStorage;
    function getUIntValue(bytes32 record) external view returns (uint){
        return UIntStorage[record];
    }
    function setUIntValue(bytes32 record, uint value) external
        onlyAssociatedContract
    {
        UIntStorage[record] = value;
    }
    function deleteUIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete UIntStorage[record];
    }
    function getStringValue(bytes32 record) external view returns (string memory){
        return StringStorage[record];
    }
    function setStringValue(bytes32 record, string value) external
        onlyAssociatedContract
    {
        StringStorage[record] = value;
    }
    function deleteStringValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete StringStorage[record];
    }
    function getAddressValue(bytes32 record) external view returns (address){
        return AddressStorage[record];
    }
    function setAddressValue(bytes32 record, address value) external
        onlyAssociatedContract
    {
        AddressStorage[record] = value;
    }
    function deleteAddressValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete AddressStorage[record];
    }
    function getBytesValue(bytes32 record) external view returns
    (bytes memory){
        return BytesStorage[record];
    }
    function setBytesValue(bytes32 record, bytes value) external
        onlyAssociatedContract
    {
        BytesStorage[record] = value;
    }
    function deleteBytesValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BytesStorage[record];
    }
    function getBytes32Value(bytes32 record) external view returns (bytes32)
    {
        return Bytes32Storage[record];
    }
    function setBytes32Value(bytes32 record, bytes32 value) external
        onlyAssociatedContract
    {
        Bytes32Storage[record] = value;
    }
    function deleteBytes32Value(bytes32 record) external
        onlyAssociatedContract
    {
        delete Bytes32Storage[record];
    }
    function getBooleanValue(bytes32 record) external view returns (bool)
    {
        return BooleanStorage[record];
    }
    function setBooleanValue(bytes32 record, bool value) external
        onlyAssociatedContract
    {
        BooleanStorage[record] = value;
    }
    function deleteBooleanValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete BooleanStorage[record];
    }
    function getIntValue(bytes32 record) external view returns (int){
        return IntStorage[record];
    }
    function setIntValue(bytes32 record, int value) external
        onlyAssociatedContract
    {
        IntStorage[record] = value;
    }
    function deleteIntValue(bytes32 record) external
        onlyAssociatedContract
    {
        delete IntStorage[record];
    }
}