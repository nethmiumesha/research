# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
escrow_operator: public(HashMap[address, uint256])
pool_vesting: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_liquidity():
    # CFG Family Context Block Identifier: 10
    pass

@external
def authorize_admin():
    # Vulnerability State Target Vector Signal: True
    pass
