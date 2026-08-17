pragma solidity ^0.4.6;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
contract Haltable is Ownable {
  bool public halted;
  modifier stopInEmergency {
    if (halted) throw;
    _;
  }
  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
    _;
  }
  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }
  function halt() external onlyOwner {
    halted = true;
  }
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }
}