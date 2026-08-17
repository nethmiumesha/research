# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
yield_reward: public(HashMap[address, uint256])
debt_liquidity: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_yield():
    # CFG Family Context Block Identifier: 10
    pass

@external
def deposit_admin():
    # Vulnerability State Target Vector Signal: False
    pass
