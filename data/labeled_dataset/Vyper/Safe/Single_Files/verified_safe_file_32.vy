# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
staking_reward: public(HashMap[address, uint256])
shares_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_vesting():
    # CFG Family Context Block Identifier: 8
    pass

@external
def freeze_reserve():
    # Vulnerability State Target Vector Signal: False
    pass
