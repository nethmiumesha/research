pragma solidity ^0.4.11;
import "./MiniMeToken.sol";
import "./REALCrowdsale.sol";
import "./SafeMath.sol";
import "./Owned.sol";
import "./ERC20Token.sol";
contract REALPlaceHolder is TokenController, Owned {
    using SafeMath for uint256;
    MiniMeToken public real;
    REALCrowdsale public contribution;
    uint256 public activationTime;
    function REALPlaceHolder(address _owner, address _real, address _contribution) {
        owner = _owner;
        real = MiniMeToken(_real);
        contribution = REALCrowdsale(_contribution);
    }
    function changeController(address _newController) public onlyOwner {
        real.changeController(_newController);
        ControllerChanged(_newController);
    }
    function proxyPayment(address) public payable returns (bool) {
        return false;
    }
    function onTransfer(address _from, address, uint256) public returns (bool) {
      return transferable(_from);
    }
    function onApprove(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }
    function transferable(address _from) internal returns (bool) {
        if (activationTime == 0) {
            uint256 f = contribution.finalizedTime();
            if (f > 0) {
                activationTime = f.add(1 weeks);
            } else {
                return false;
            }
        }
        return (getTime() > activationTime) || (_from == owner);
    }
    function getTime() internal returns (uint256) {
        return now;
    }
    function claimTokens(address _token) public onlyOwner {
        if (real.controller() == address(this)) {
            real.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }
        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event ControllerChanged(address indexed _newController);
    event MessageBool(bool _message);
}