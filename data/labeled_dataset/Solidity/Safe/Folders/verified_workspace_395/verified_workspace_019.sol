pragma solidity ^0.4.8;
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./StandardTokenExt.sol";
import "./UpgradeAgent.sol";
contract UpgradeableToken is StandardTokenExt {
  address public upgradeMaster;
  UpgradeAgent public upgradeAgent;
  uint256 public totalUpgraded;
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);
  event UpgradeAgentSet(address agent);
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }
  function upgrade(uint256 value) public {
      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        throw;
      }
      if (value == 0) throw;
      balances[msg.sender] = balances[msg.sender].sub(value);
      totalSupply_ = totalSupply_.sub(value);
      totalUpgraded = totalUpgraded.add(value);
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }
  function setUpgradeAgent(address agent) external {
      if(!canUpgrade()) {
        throw;
      }
      if (agent == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      if (getUpgradeState() == UpgradeState.Upgrading) throw;
      upgradeAgent = UpgradeAgent(agent);
      if(!upgradeAgent.isUpgradeAgent()) throw;
      if (upgradeAgent.originalSupply() != totalSupply_) throw;
      UpgradeAgentSet(upgradeAgent);
  }
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }
  function canUpgrade() public constant returns(bool) {
     return true;
  }
}