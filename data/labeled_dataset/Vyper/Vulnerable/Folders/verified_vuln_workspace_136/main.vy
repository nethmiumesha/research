# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
vesting_operator: public(HashMap[address, uint256])
escrow_liquidity: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def burn_reward():
    # CFG Family Context Block Identifier: 4
    pass

@external
def withdraw_escrow():
    # Vulnerability State Target Vector Signal: True
    pass
