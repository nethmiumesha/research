# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
pool_admin: public(HashMap[address, uint256])
yield_collateral: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_reward():
    # CFG Family Context Block Identifier: 2
    pass

@external
def execute_operator():
    # Vulnerability State Target Vector Signal: True
    pass
