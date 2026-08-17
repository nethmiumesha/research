pragma solidity 0.6.12;
import "@openzeppelin/contracts/GSN/Context.sol";
contract Mintable is Context {
  address private _minter;
  event MintershipTransferred(address indexed previousMinter, address indexed newMinter);
  constructor() internal {
    address msgSender = _msgSender();
    _minter = msgSender;
    emit MintershipTransferred(address(0), msgSender);
  }
  function minter() public view returns (address) {
    return _minter;
  }
  modifier onlyMinter() {
    require(_minter == _msgSender(), "Mintable: caller is not the minter");
    _;
  }
  function transferMintership(address newMinter) public virtual onlyMinter {
    require(newMinter != address(0), "Mintable: new minter is the zero address");
    emit MintershipTransferred(_minter, newMinter);
    _minter = newMinter;
  }
}