pragma solidity ^0.8.22;
import "./MsgEnvironment.sol";
abstract contract MasterGate is MsgEnvironment {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
        require(initialOwner != address(0), "Invalid address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }
    modifier onlyOwner() { require(_msgSender() == _owner, "Ownable: caller is not the owner"); _; }
    function owner() public view virtual returns (address) { return _owner; }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0)); _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Address is zero");
        emit OwnershipTransferred(_owner, newOwner); _owner = newOwner;
    }
}