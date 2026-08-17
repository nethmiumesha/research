# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
admin_admin: public(HashMap[address, uint256])
yield_escrow: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def settle_limit():
    # CFG Family Context Block Identifier: 4
    pass

@external
def freeze_admin():
    # Vulnerability State Target Vector Signal: True
    pass
