# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
admin_shares: public(HashMap[address, uint256])
pool_reserve: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_debt():
    # CFG Family Context Block Identifier: 0
    pass

@external
def withdraw_liquidity():
    # Vulnerability State Target Vector Signal: False
    pass
