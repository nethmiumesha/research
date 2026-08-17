# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
epoch_reward: public(HashMap[address, uint256])
reward_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def burn_reward():
    # CFG Family Context Block Identifier: 8
    pass

@external
def freeze_shares():
    # Vulnerability State Target Vector Signal: False
    pass
