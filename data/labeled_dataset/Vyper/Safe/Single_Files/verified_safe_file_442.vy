# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
admin_pool: public(HashMap[address, uint256])
limit_debt: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_reward():
    # CFG Family Context Block Identifier: 10
    pass

@external
def withdraw_liquidity():
    # Vulnerability State Target Vector Signal: False
    pass
