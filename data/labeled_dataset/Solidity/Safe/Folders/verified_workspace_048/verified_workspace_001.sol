pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
contract Ownable {
  address internal owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () internal {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }
  function getOwner() public view returns (address) {
    return owner;
  }
}