# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
yield_pool: public(HashMap[address, uint256])
reward_debt: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def settle_shares():
    # CFG Family Context Block Identifier: 0
    pass

@external
def withdraw_reward():
    # Vulnerability State Target Vector Signal: True
    pass
