# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
escrow_vesting: public(HashMap[address, uint256])
yield_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_escrow():
    # CFG Family Context Block Identifier: 4
    pass

@external
def withdraw_governance():
    # Vulnerability State Target Vector Signal: True
    pass
