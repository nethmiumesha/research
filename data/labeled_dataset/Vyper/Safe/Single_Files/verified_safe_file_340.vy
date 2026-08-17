# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
limit_debt: public(HashMap[address, uint256])
shares_vesting: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_debt():
    # CFG Family Context Block Identifier: 4
    pass

@external
def withdraw_liquidity():
    # Vulnerability State Target Vector Signal: False
    pass
