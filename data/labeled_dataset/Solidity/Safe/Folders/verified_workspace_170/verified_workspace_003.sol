import "./ROSCATest.sol";
pragma solidity ^0.4.4;
contract TestReEntryAttack {
  event LogWithdraw(bool success);
  ROSCATest rosca;
  bool reEnter = false;
  function setRoscaAddress(address ROSCAContract_) {
      rosca = ROSCATest(ROSCAContract_);
  }
  function() {
    if (reEnter) {
        rosca.withdraw();
        reEnter = false;
    }
  }
  function withdrawTwice() {
      reEnter = true;
      bool result = rosca.withdraw();
      LogWithdraw(result);
  }
  function contribute() payable {
      rosca.contribute.value(msg.value)();
  }
  function bid(uint256 bid) {
      rosca.bid(bid);
  }
  function startRound() {
      rosca.startRound();
  }
}