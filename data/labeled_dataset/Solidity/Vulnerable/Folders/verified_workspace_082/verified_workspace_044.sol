pragma solidity ^0.5.16;
import "./VBep20Delegate.sol";
interface XvsLike {
  function delegate(address delegatee) external;
}
contract VXvsLikeDelegate is VBep20Delegate {
  constructor() public VBep20Delegate() {}
  function _delegateXvsLikeTo(address xvsLikeDelegatee) external {
    require(msg.sender == admin, "only the admin may set the xvs-like delegate");
    XvsLike(underlying).delegate(xvsLikeDelegatee);
  }
}