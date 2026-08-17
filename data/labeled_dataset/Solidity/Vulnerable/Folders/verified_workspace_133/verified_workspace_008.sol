pragma solidity ^0.8.22;
abstract contract MsgEnvironment {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}